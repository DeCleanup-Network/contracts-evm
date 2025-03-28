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
import "../interfaces/INFTCollection.sol";

/**
 * @title DipNft
 * @dev NFT contract for the Dip platform with level progression and rewards
 * Implements soulbound (non-transferable) tokens with admin-approved transfer capabilities
 */
contract DipNft is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, INFTCollection {
    using Strings for uint256;

    // Custom errors
    error NFT__TokenNotExists(uint256 tokenId);
    error NFT__NotVerifiedPOI(address user);
    error NFT__RewardsContractNotSet();
    error NFT__TransferRestricted(uint256 tokenId);
    error NFT__InvalidRewardsContract(address contractAddress);
    error NFT__InvalidAddress(address invalidAddress);
    error NFT__AlreadyMinted(address user);
    error NFT__NotTokenOwner(address user, uint256 tokenId, address owner);
    error NFT__MaxLevelReached(uint256 tokenId, uint256 currentLevel, uint256 maxLevel);
    error NFT__InvalidLevelRange(uint256 level, uint256 maxLevel);
    error NFT__UserHasNoNFT(address user);
    error NFT__TransferNotAuthorized(uint256 tokenId);

    // Constants (these don't use storage slots)
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant REWARD_AMOUNT = 10; // Amount of DCU to reward
    string public constant SOULBOUND_NOTICE = "This is a soulbound NFT.";

    // Group address variables (each uses a full slot)
    address public _rewardsContractAddress;

    // Group uint256 variables (each uses a full slot)
    uint256 private _tokenIdCounter;

    // Group bool mappings together (these can't share slots in mappings, but organizing for clarity)
    mapping(address => bool) public verifiedPOI;
    mapping(address => bool) public _userHasMinted;
    mapping(uint256 => bool) private _transferAuthorized;

    // Group address mappings
    mapping(uint256 => address) private _authorizedRecipient;

    // Group uint256 mappings
    mapping(address => uint256) public userLevel;
    mapping(uint256 => uint256) public nftLevel;
    mapping(uint256 => uint256) public impactLevel;
    mapping(address => uint256) private _userTokenIds;

    // Events
    event Minted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed userLevel,
        uint256 nftLevel
    );
    event DCURewards(address indexed to, uint256 indexed amount);
    event NFTUpgraded(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed newLevel,
        uint256 userLevel
    );
    event DCURewardTriggered(address indexed to, uint256 indexed amount);
    event RewardsContractUpdated(
        address indexed oldContract,
        address indexed newContract
    );
    event POIVerified(address indexed user);
    event ImpactLevelUpdated(uint256 indexed tokenId, uint256 indexed newLevel);
    event RewardDistributed(
        address indexed to,
        uint256 indexed amount,
        uint256 indexed level
    );
    
    // Enhanced events for tracking and indexing
    event NFTEvent(
        address indexed user,
        uint256 indexed tokenId,
        uint256 oldLevel,
        uint256 newLevel,
        uint256 timestamp,
        uint256 rewardAmount,
        string eventType
    );

    // Soulbound events
    event TransferAuthorized(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );
    event TransferAuthorizationRevoked(uint256 indexed tokenId);
    event NFTTransferredByAdmin(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    /**
     * @dev Modifier to check if a token ID is valid
     */
    modifier validTokenId(uint256 tokenId) {
        if (!_exists(tokenId)) revert NFT__TokenNotExists(tokenId);
        _;
    }

    /**
     * @dev Constructor initializes the NFT collection
     * @param _rewardsContract The address of the rewards contract
     */
    constructor(address _rewardsContract) ERC721("DipNFT", "DIP") Ownable(msg.sender) {
        _tokenIdCounter = 0;
        _rewardsContractAddress = _rewardsContract;
    }

    /**
     * @dev Modifier to restrict access to verified POI users
     */
    modifier onlyVerifiedPOI() {
        if (!verifiedPOI[msg.sender]) revert NFT__NotVerifiedPOI(msg.sender);
        _;
    }

    /**
     * @dev Modifier to check if rewards contract is set
     */
    modifier rewardsContractSet() {
        if (_rewardsContractAddress == address(0)) revert NFT__RewardsContractNotSet();
        _;
    }

    /**
     * @dev Restricts transfers to implement soulbound functionality
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        // Check if this is an authorized transfer
        if (!(_transferAuthorized[tokenId] && to == _authorizedRecipient[tokenId]))
            revert NFT__TransferRestricted(tokenId);

        // Reset authorization after transfer
        _transferAuthorized[tokenId] = false;
        _authorizedRecipient[tokenId] = address(0);

        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Restricts safe transfers to implement soulbound functionality
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) {
        // Check if this is an authorized transfer
        if (!(_transferAuthorized[tokenId] && to == _authorizedRecipient[tokenId]))
            revert NFT__TransferRestricted(tokenId);

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
        if (_rewardsContract == address(0))
            revert NFT__InvalidRewardsContract(_rewardsContract);
            
        address oldContract = _rewardsContractAddress;
        _rewardsContractAddress = _rewardsContract;
        emit RewardsContractUpdated(oldContract, _rewardsContract);
    }

    /**
     * @dev Verify a user as POI
     * @param _poi The address of the user to verify
     */
    function verifyPOI(address _poi) public onlyOwner {
        if (_poi == address(0)) revert NFT__InvalidAddress(_poi);
        verifiedPOI[_poi] = true;
        emit POIVerified(_poi);
    }

    /**
     * @dev Authorize a specific NFT transfer (admin only)
     * @param tokenId The token ID to authorize for transfer
     * @param to The recipient address for the authorized transfer
     */
    function authorizeTransfer(uint256 tokenId, address to) external onlyOwner validTokenId(tokenId) {
        if (to == address(0)) revert NFT__InvalidAddress(to);

        _transferAuthorized[tokenId] = true;
        _authorizedRecipient[tokenId] = to;

        emit TransferAuthorized(tokenId, ownerOf(tokenId), to);
    }

    /**
     * @dev Revoke a previously authorized transfer (admin only)
     * @param tokenId The token ID to revoke transfer authorization for
     */
    function revokeTransferAuthorization(uint256 tokenId) external onlyOwner validTokenId(tokenId) {
        if (!_transferAuthorized[tokenId]) revert NFT__TransferNotAuthorized(tokenId);

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
    function isTransferAuthorized(
        uint256 tokenId
    ) external view returns (bool authorized, address recipient) {
        return (_transferAuthorized[tokenId], _authorizedRecipient[tokenId]);
    }

    /**
     * @dev Admin-approved transfer of an NFT (for wallet recovery, etc.)
     * @param tokenId The token ID to transfer
     * @param to The recipient address
     */
    function adminTransfer(uint256 tokenId, address to) external onlyOwner validTokenId(tokenId) {
        if (to == address(0)) revert NFT__InvalidAddress(to);

        address currentOwner = ownerOf(tokenId);

        // Temporarily authorize the transfer
        _transferAuthorized[tokenId] = true;
        _authorizedRecipient[tokenId] = to;

        // Transfer the token
        _transfer(currentOwner, to, tokenId);

        emit NFTTransferredByAdmin(tokenId, currentOwner, to);
    }

    /**
     * @dev Process rewards for the user
     * @param user Address of the user to reward
     */
    function _processReward(address user) internal {
        emit DCURewards(user, REWARD_AMOUNT);
        
        if (_rewardsContractAddress != address(0)) {
            try IRewards(_rewardsContractAddress).distributeDCU(user, REWARD_AMOUNT) {
                emit DCURewardTriggered(user, REWARD_AMOUNT);
            } catch {
                emit DCURewardTriggered(user, REWARD_AMOUNT);
            }
        }
    }

    /**
     * @dev Implementation of the mint function from INFTCollection interface
     * @param to Address to mint the token to
     * @return The ID of the minted token
     */
    function mint(address to) external override onlyOwner returns (uint256) {
        if (!verifiedPOI[to]) revert NFT__NotVerifiedPOI(to);
        if (_userHasMinted[to]) revert NFT__AlreadyMinted(to);

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Add token ID mapping
        _userTokenIds[to] = tokenId;

        // Initialize NFT and user levels
        userLevel[to] = 1;
        nftLevel[tokenId] = 1;
        impactLevel[tokenId] = 1; // Initialize impact level
        _userHasMinted[to] = true;

        // Emit events
        emit Minted(to, tokenId, 1, 1);
        
        // Enhanced event for NFT claim
        emit NFTEvent(
            to,
            tokenId,
            0,
            1,
            block.timestamp,
            REWARD_AMOUNT,
            "CLAIM"
        );

        // Notify reward manager of NFT minting
        if (_rewardsContractAddress != address(0)) {
            try DCURewardManager(_rewardsContractAddress).updateNftMintStatus(to, true) {
                // Successfully notified reward manager
            } catch {
                // Continue even if notification fails
            }
        }

        return tokenId;
    }

    /**
     * @dev Mint a new NFT for a verified POI user
     */
    function safeMint() public onlyVerifiedPOI nonReentrant {
        if (_userHasMinted[msg.sender]) revert NFT__AlreadyMinted(msg.sender);

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(msg.sender, tokenId);

        // Add token ID mapping
        _userTokenIds[msg.sender] = tokenId;

        // Initialize NFT and user levels
        userLevel[msg.sender] = 1;
        nftLevel[tokenId] = 1;
        impactLevel[tokenId] = 1; // Initialize impact level
        _userHasMinted[msg.sender] = true;

        // Emit events - legacy and enhanced
        emit Minted(msg.sender, tokenId, 1, 1);

        // Enhanced event for NFT claim
        emit NFTEvent(
            msg.sender,
            tokenId,
            0, // No old level for new mint
            1, // New level is 1
            block.timestamp,
            REWARD_AMOUNT,
            "CLAIM"
        );

        // Notify reward manager of NFT minting
        if (_rewardsContractAddress != address(0)) {
            try DCURewardManager(_rewardsContractAddress).updateNftMintStatus(msg.sender, true) {
                // Successfully notified reward manager
            } catch {
                // Continue even if notification fails
            }
        }

        // Process reward after verification sequence is established
        _processReward(msg.sender);
    }

    /**
     * @dev Upgrade an NFT's level
     * @param tokenId The ID of the token to upgrade
     */
    function upgradeNFT(uint256 tokenId) external onlyVerifiedPOI nonReentrant validTokenId(tokenId) {
        if (!_userHasMinted[msg.sender]) revert NFT__UserHasNoNFT(msg.sender);
        
        if (!_isAuthorized(_ownerOf(tokenId), msg.sender, tokenId))
            revert NFT__NotTokenOwner(msg.sender, tokenId, _ownerOf(tokenId));
            
        if (nftLevel[tokenId] >= MAX_LEVEL)
            revert NFT__MaxLevelReached(tokenId, nftLevel[tokenId], MAX_LEVEL);

        // Store the old level for the event
        uint256 oldLevel = nftLevel[tokenId];

        // Increment levels
        nftLevel[tokenId] += 1;
        userLevel[msg.sender] += 1;

        // Emit standard upgrade event
        emit NFTUpgraded(
            msg.sender,
            tokenId,
            nftLevel[tokenId],
            userLevel[msg.sender]
        );

        // Enhanced event for NFT upgrade
        emit NFTEvent(
            msg.sender,
            tokenId,
            oldLevel,
            nftLevel[tokenId],
            block.timestamp,
            REWARD_AMOUNT,
            "UPGRADE"
        );

        // Ensure reward manager is still aware of the NFT status
        if (_rewardsContractAddress != address(0)) {
            try DCURewardManager(_rewardsContractAddress).updateNftMintStatus(msg.sender, true) {
                // Successfully updated reward manager
            } catch {
                // Continue even if update fails
            }
        }

        // Process reward
        _processReward(msg.sender);
    }

    /**
     * @dev Distributes rewards to a user based on their NFT level
     * @param user Address of the user to reward
     * @param level Level of the NFT
     */
    function distributeReward(address user, uint256 level) external onlyOwner {
        if (user == address(0)) revert NFT__InvalidAddress(user);
        if (!verifiedPOI[user]) revert NFT__NotVerifiedPOI(user);
        if (level == 0 || level > MAX_LEVEL) revert NFT__InvalidLevelRange(level, MAX_LEVEL);

        // Emit event for reward distribution
        emit DCURewardTriggered(user, REWARD_AMOUNT);
        emit RewardDistributed(user, REWARD_AMOUNT, level);
    }

    /**
     * @dev Hook that is called during any token transfer. This includes minting and burning.
     * Automatically maintains the _userTokenIds mapping to track token ownership.
     * @param to The address receiving the token (address(0) for burning)
     * @param tokenId The token ID being transferred
     * @param auth The address that initiated the transfer
     * @return address The address that previously owned the token (address(0) for minting)
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721) returns (address) {
        address from = super._update(to, tokenId, auth);

        if (from != address(0)) {
            // Remove the token from the previous owner
            delete _userTokenIds[from];
        }

        if (to != address(0)) {
            // Assign the token to the new owner
            _userTokenIds[to] = tokenId;
        }

        return from;
    }

    /**
     * @dev Update the impact level of an NFT
     * @param tokenId The ID of the token to update
     * @param newImpactLevel The new impact level
     */
    function updateImpactLevel(
        uint256 tokenId,
        uint256 newImpactLevel
    ) external onlyOwner validTokenId(tokenId) {
        if (newImpactLevel == 0 || newImpactLevel > MAX_LEVEL) 
            revert NFT__InvalidLevelRange(newImpactLevel, MAX_LEVEL);
            
        impactLevel[tokenId] = newImpactLevel;
        emit ImpactLevelUpdated(tokenId, newImpactLevel);
    }

    /**
     * @dev Get the category of an NFT based on its level
     * @param level The level of the NFT
     * @return The category of the NFT
     */
    function _getNFTCategory(
        uint256 level
    ) internal pure returns (string memory) {
        if (level >= 1 && level <= 3) return "Newbie";
        if (level >= 4 && level <= 6) return "Pro";
        if (level >= 7 && level <= 9) return "Hero";
        if (level == 10) return "Guardian";
        return "Invalid";
    }

    /**
     * @dev Check if a token exists
     * @param tokenId The ID of the token
     * @return Whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Get NFT data for a user
     * @param user The address of the user
     * @return tokenId The ID of the user's NFT
     * @return impact The impact level of the NFT
     * @return level The level of the NFT
     */
    function getUserNFTData(
        address user
    ) external view returns (uint256 tokenId, uint256 impact, uint256 level) {
        if (!_userHasMinted[user]) revert NFT__UserHasNoNFT(user);
        tokenId = _userTokenIds[user];
        if (_ownerOf(tokenId) != user) revert NFT__NotTokenOwner(user, tokenId, _ownerOf(tokenId));
        return (tokenId, impactLevel[tokenId], nftLevel[tokenId]);
    }

    /**
     * @dev Override tokenURI function
     * @param tokenId The ID of the token
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) validTokenId(tokenId) returns (string memory) {
        string memory level = nftLevel[tokenId].toString();
        string memory impact = impactLevel[tokenId].toString();
        string memory category = _getNFTCategory(nftLevel[tokenId]);
        
        // Extremely simplified metadata JSON
        string memory json = string(
            abi.encodePacked(
                '{"name":"DipNFT #', 
                tokenId.toString(),
                '","description":"DipNFT",',
                '"attributes":[{"trait_type":"Level","value":"', 
                level,
                '"},{"trait_type":"Impact","value":"', 
                impact,
                '"},{"trait_type":"Category","value":"', 
                category,
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Override supportsInterface function
     * @param interfaceId The interface ID to check
     * @return Whether the contract supports the interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Check if a user has already minted an NFT (implementation of INFTCollection interface)
     * @param user Address of the user
     * @return Whether the user has minted an NFT
     */
    function hasMinted(address user) external view override returns (bool) {
        return _userHasMinted[user];
    }

    /**
     * @dev Get the rewards contract address (implementation of INFTCollection interface)
     * @return The address of the rewards contract
     */
    function rewardsContract() external view override returns (address) {
        return _rewardsContractAddress;
    }

    /**
     * @dev Override balanceOf function to implement INFTCollection interface
     * @param owner Address of the owner
     * @return The number of tokens owned by the owner
     */
    function balanceOf(address owner) public view virtual override(ERC721, IERC721, INFTCollection) returns (uint256) {
        return super.balanceOf(owner);
    }
}
