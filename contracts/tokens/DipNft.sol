// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IRewards.sol";
import "../DCURewardManager.sol";

/**
 * @title DipNft
 * @dev NFT contract for the Dip platform with level progression and rewards
 * Implements soulbound (non-transferable) tokens with admin-approved transfer capabilities
 */
contract DipNft is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    // Constants
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant REWARD_AMOUNT = 10; // Amount of DCU to reward
    string public constant SOULBOUND_NOTICE = "This is a soulbound NFT representing your personal environmental impact.";
    
    // State variables
    uint256 private _tokenIdCounter;
    address public rewardsContract;
    
    // Soulbound transfer authorization mappings
    mapping(uint256 => bool) private _transferAuthorized;
    mapping(uint256 => address) private _authorizedRecipient;
    
    // Mappings
    mapping(address => uint256) public userLevel;
    mapping(address => bool) public verifiedPOI;
    mapping(address => bool) public hasMinted;
    mapping(uint256 => uint256) public nftLevel;
    mapping(uint256 => uint256) public impactLevel;
    
    // Events
    event Minted(address indexed to, uint256 indexed tokenId, uint256 indexed userLevel, uint256 nftLevel);
    event DCURewards(address indexed to, uint256 indexed amount);
    event NFTUpgraded(address indexed to, uint256 indexed tokenId, uint256 indexed newLevel, uint256 userLevel);
    event DCURewardTriggered(address indexed to, uint256 indexed amount);
    event RewardsContractUpdated(address indexed oldContract, address indexed newContract);
    event POIVerified(address indexed user);
    event ImpactLevelUpdated(uint256 indexed tokenId, uint256 indexed newLevel);
    event RewardDistributed(address indexed to, uint256 indexed amount, uint256 indexed level);
    
    // Soulbound events
    event TransferAuthorized(uint256 indexed tokenId, address indexed from, address indexed to);
    event TransferAuthorizationRevoked(uint256 indexed tokenId);
    event NFTTransferredByAdmin(uint256 indexed tokenId, address indexed from, address indexed to);

    /**
     * @dev Constructor initializes the NFT collection
     */
    constructor() ERC721("DipNFT", "DIP") Ownable(msg.sender) {
        _tokenIdCounter = 0;
    }

    /**
     * @dev Modifier to restrict access to verified POI users
     */
    modifier onlyVerifiedPOI() {
        require(verifiedPOI[msg.sender], "You are not a verified POI");
        _;
    }
    
    /**
     * @dev Modifier to check if rewards contract is set
     */
    modifier rewardsContractSet() {
        require(rewardsContract != address(0), "Rewards contract not set");
        _;
    }

    /**
     * @dev Restricts transfers to implement soulbound functionality
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override (ERC721, IERC721) {
        // Check if this is an authorized transfer
        require(
            _transferAuthorized[tokenId] && to == _authorizedRecipient[tokenId],
            "DipNft: transfers are restricted (soulbound NFT)"
        );
        
        // Reset authorization after transfer
        _transferAuthorized[tokenId] = false;
        _authorizedRecipient[tokenId] = address(0);
        
        super.transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Restricts safe transfers to implement soulbound functionality
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override (ERC721, IERC721) {
        // Check if this is an authorized transfer
        require(
            _transferAuthorized[tokenId] && to == _authorizedRecipient[tokenId],
            "DipNft: transfers are restricted (soulbound NFT)"
        );
        
        // Reset authorization after transfer
        _transferAuthorized[tokenId] = false;
        _authorizedRecipient[tokenId] = address(0);
        
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Set the rewards contract address
     * @param _rewardsContract The address of the rewards contract
     */
    function setRewardsContract(address _rewardsContract) external onlyOwner {
        require(_rewardsContract != address(0), "Invalid rewards contract address");
        address oldContract = rewardsContract;
        rewardsContract = _rewardsContract;
        emit RewardsContractUpdated(oldContract, _rewardsContract);
    }

    /**
     * @dev Verify a user as POI
     * @param _poi The address of the user to verify
     */
    function verifyPOI(address _poi) public onlyOwner {
        require(_poi != address(0), "Invalid address");
        verifiedPOI[_poi] = true;
        emit POIVerified(_poi);
    }
    
    /**
     * @dev Authorize a specific NFT transfer (admin only)
     * @param tokenId The token ID to authorize for transfer
     * @param to The recipient address for the authorized transfer
     */
    function authorizeTransfer(uint256 tokenId, address to) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(to != address(0), "Invalid recipient");
        
        _transferAuthorized[tokenId] = true;
        _authorizedRecipient[tokenId] = to;
        
        emit TransferAuthorized(tokenId, ownerOf(tokenId), to);
    }

    /**
     * @dev Revoke a previously authorized transfer (admin only)
     * @param tokenId The token ID to revoke transfer authorization for
     */
    function revokeTransferAuthorization(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(_transferAuthorized[tokenId], "Transfer not authorized");
        
        _transferAuthorized[tokenId] = false;
        _authorizedRecipient[tokenId] = address(0);
        
        emit TransferAuthorizationRevoked(tokenId);
    }

    /**
     * @dev Check if a transfer is authorized for a token
     * @param tokenId The token ID to check authorization for
     * @return authorized Whether the transfer is authorized
     * @return recipient The authorized recipient address
     */
    function isTransferAuthorized(uint256 tokenId) external view returns (bool authorized, address recipient) {
        return (_transferAuthorized[tokenId], _authorizedRecipient[tokenId]);
    }

    /**
     * @dev Admin-approved transfer of an NFT (for wallet recovery, etc.)
     * @param tokenId The token ID to transfer
     * @param to The recipient address
     */
    function adminTransfer(uint256 tokenId, address to) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(to != address(0), "Invalid recipient");
        
        address currentOwner = ownerOf(tokenId);
        
        // Temporarily authorize the transfer
        _transferAuthorized[tokenId] = true;
        _authorizedRecipient[tokenId] = to;
        
        // Transfer the token
        _transfer(currentOwner, to, tokenId);
        
        emit NFTTransferredByAdmin(tokenId, currentOwner, to);
    }

    /**
     * @dev Mint a new NFT for a verified POI user
     */
    function safeMint() public onlyVerifiedPOI nonReentrant {
        require(hasMinted[msg.sender] == false, "You have already minted a token");
        
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(msg.sender, tokenId);
        
        // Initialize NFT and user levels
        userLevel[msg.sender] = 1;
        nftLevel[tokenId] = 1;
        impactLevel[tokenId] = 1; // Initialize impact level
        hasMinted[msg.sender] = true;

        emit Minted(msg.sender, tokenId, 1, 1);
        
        // Emit reward event - actual rewards will be distributed by the owner
        if (rewardsContract != address(0)) {
            emit DCURewards(msg.sender, REWARD_AMOUNT);
        }
    }

    /**
     * @dev Upgrade an NFT's level
     * @param tokenId The ID of the token to upgrade
     */
    function upgradeNFT(uint256 tokenId) external onlyVerifiedPOI nonReentrant {
        require(hasMinted[msg.sender], "You have not minted a token yet");
        require(_isAuthorized(_ownerOf(tokenId), msg.sender, tokenId), "You don't own this token");
        require(nftLevel[tokenId] < MAX_LEVEL, "You have reached the maximum level");

        // Increment levels
        nftLevel[tokenId] += 1;
        userLevel[msg.sender] += 1;

        emit NFTUpgraded(msg.sender, tokenId, nftLevel[tokenId], userLevel[msg.sender]);
        
        // Emit reward event - actual rewards will be distributed by the owner
        if (rewardsContract != address(0)) {
            emit DCURewardTriggered(msg.sender, REWARD_AMOUNT);
        }
    }
    
    /**
     * @dev Distributes rewards to a user based on their NFT level
     * @param user Address of the user to reward
     * @param level Level of the NFT
     */
    function distributeReward(address user, uint256 level) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(verifiedPOI[user], "User is not a verified POI");
        
        // Emit event for reward distribution
        emit DCURewardTriggered(user, REWARD_AMOUNT);
        emit RewardDistributed(user, REWARD_AMOUNT, level);
    }
    
    /**
     * @dev Update the impact level of an NFT
     * @param tokenId The ID of the token to update
     * @param newImpactLevel The new impact level
     */
    function updateImpactLevel(uint256 tokenId, uint256 newImpactLevel) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        impactLevel[tokenId] = newImpactLevel;
        emit ImpactLevelUpdated(tokenId, newImpactLevel);
    }

    /**
     * @dev Get NFT data for a user
     * @param user The address of the user
     * @return tokenId The ID of the user's NFT
     * @return impact The impact level of the NFT
     * @return level The level of the NFT
     */
    function getUserNFTData(address user) external view returns (uint256 tokenId, uint256 impact, uint256 level) {
        require(hasMinted[user], "User has no NFT");

        // Optimize by checking only tokens owned by the user
        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            try this.ownerOf(i) returns (address owner) {
                if (owner == user) {
                    return (i, impactLevel[i], nftLevel[i]);
                }
            } catch {
                // Skip non-existent tokens
                continue;
            }
        }
        
        revert("No NFT found");
    }

    /**
     * @dev Get the category of an NFT based on its level
     * @param level The level of the NFT
     * @return The category of the NFT
     */
    function getNFTCategory(uint256 level) external pure returns (string memory) {
        if (level >= 1 && level <= 3) return "Newbie";
        if (level >= 4 && level <= 6) return "Pro";
        if (level >= 7 && level <= 9) return "Hero";
        if (level == 10) return "Guardian";
        return "Invalid";
    }

    /**
     * @dev Override supportsInterface function
     * @param interfaceId The interface ID to check
     * @return Whether the contract supports the interface
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Override tokenURI function
     * @param tokenId The ID of the token
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        string memory name = string(abi.encodePacked("DipNFT #", tokenId.toString()));
        string memory description = string(abi.encodePacked(
            "This is an on-chain NFT with impact level progression. ", 
            SOULBOUND_NOTICE
        ));
        string memory levelStr = nftLevel[tokenId].toString();
        string memory impactStr = impactLevel[tokenId].toString();
        string memory category = this.getNFTCategory(nftLevel[tokenId]);

        string memory json = string(
            abi.encodePacked(
                '{"name":"', name, '",',
                '"description":"', description, '",',
                '"attributes":[{"trait_type":"Impact Level","value":"', impactStr, '"},',
                '{"trait_type":"NFT Level","value":"', levelStr, '"},',
                '{"trait_type":"Category","value":"', category, '"},',
                '{"trait_type":"Soulbound","value":"Yes"}],',
                '"image":"', generateSVG(tokenId), '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Generate an SVG image for an NFT
     * @param tokenId The ID of the token
     * @return The SVG image as a data URI
     */
    function generateSVG(uint256 tokenId) internal view returns (string memory) {
        // Generate dynamic SVG based on NFT attributes
        string memory levelText = nftLevel[tokenId].toString();
        string memory categoryText = this.getNFTCategory(nftLevel[tokenId]);
        
        // Generate gradient colors based on level
        string memory startColor;
        string memory endColor;
        
        if (nftLevel[tokenId] >= 1 && nftLevel[tokenId] <= 3) {
            startColor = "#3498db"; // Blue
            endColor = "#2ecc71"; // Green
        } else if (nftLevel[tokenId] >= 4 && nftLevel[tokenId] <= 6) {
            startColor = "#2ecc71"; // Green
            endColor = "#f1c40f"; // Yellow
        } else if (nftLevel[tokenId] >= 7 && nftLevel[tokenId] <= 9) {
            startColor = "#f1c40f"; // Yellow
            endColor = "#e74c3c"; // Red
        } else {
            startColor = "#e74c3c"; // Red
            endColor = "#9b59b6"; // Purple
        }
        
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" viewBox="0 0 350 350">',
            '<defs><linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">',
            '<stop offset="0%" stop-color="', startColor, '"/>',
            '<stop offset="100%" stop-color="', endColor, '"/></linearGradient></defs>',
            '<rect width="100%" height="100%" rx="10" ry="10" fill="url(#gradient)"/>',
            '<text x="50%" y="40%" font-size="24px" text-anchor="middle" fill="white">DipNFT Level ', levelText, '</text>',
            '<text x="50%" y="60%" font-size="18px" text-anchor="middle" fill="white">Category: ', categoryText, '</text>',
            '<text x="50%" y="80%" font-size="12px" text-anchor="middle" fill="white">Soulbound Token</text>',
            '</svg>'
        ));

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }
    
    /**
     * @dev Check if a token exists
     * @param tokenId The ID of the token
     * @return Whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}