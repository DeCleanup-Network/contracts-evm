// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRewards {
    function distributeDCU(address user, uint256 amount) external;
}

contract MyToken is ERC721, Ownable {
    
    using Strings for uint256;
    uint256 private _tokenIdCounter;
    uint256 public constant MAX_LEVEL = 10;
    address public rewardsContract;

    //mapping(address => bool) public hasToken;
    
    mapping(address => uint256) public  userLevel;

    mapping(address => string) public userRanks;
    mapping(address => bool) public verifiedPOI;
    mapping(address => bool) public hasMinted;
    mapping(uint256 => uint256) public nftLevel;
    mapping(uint256 => uint256) public impactLevel;

    event Minted(address indexed to, uint256 indexed tokenId, uint256 indexed userLevel, uint256 nftlevel);
    event DCURewards(address indexed to, uint256 indexed amount);
    event upgrade(address indexed to, uint256 indexed nftevel, uint256 indexed userLevel);
    event DCURewardTriggered(address indexed to, uint256 indexed amount);

    constructor(address initialOwner) ERC721("DipToken", "Dip") Ownable(msg.sender) {
 
    }

    modifier onlyVerifiedPOI(){
        require(verifiedPOI[msg.sender] == true, "Your are not a verified POI");
        _;
    }

    function verifyPOI(address _poi) public onlyOwner {
        verifiedPOI[_poi] = true;
    }

    function safeMint(address to, uint256 tokenId) public onlyVerifiedPOI{
        require(hasMinted[to] == false, "You have already minted a token");
        
        tokenId = _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        userLevel[to] =  1;
        nftLevel[tokenId] = 1;
        hasMinted[to] = true;

        IRewards(rewardsContract).distributeDCU(to, 10);

        emit Minted(to, tokenId, 1, 1);
        emit DCURewards(to, 10);
        
    }

    function upgradeNFT(uint256 tokenId) external onlyVerifiedPOI {
        require(hasMinted[msg.sender] == true, "You have not minted a token yet");

        uint256 currentLevel = nftLevel[tokenId];
        require(currentLevel < MAX_LEVEL, "You have reached the maximum level");

        nftLevel[tokenId] += 1;
        userLevel[msg.sender] += 1;


        IRewards(rewardsContract).distributeDCU(msg.sender, 10);
        emit upgrade(msg.sender, nftLevel[tokenId], userLevel[msg.sender]);
        emit DCURewardTriggered(msg.sender, 10);
    }

    
    function getUserNFTData(address user) external view returns (uint256 tokenId, uint256 impact, uint256 level) {
        require(hasMinted[user], "User has no NFT");

        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (ownerOf(i) == user) {
                return (i, impactLevel[i], nftLevel[i]);
            }
        }
        revert("No NFT found");
    }

    function getNFTCategory(uint256 level) external pure returns (string memory) {
        if(level >=1 && level <=3) return "Newbie";
        if (level >= 4 && level <= 6) return "Pro";
        if (level >= 7 && level <= 9) return "Hero";
        if (level == 10) return "Guardian";
        return "Invalid";
    }

   
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        string memory name = string(abi.encodePacked("DipToken #", tokenId.toString()));
        string memory description = "This is an on-chain NFT with impact level progression.";
        string memory levelStr = nftLevel[tokenId].toString();
        string memory impactStr = impactLevel[tokenId].toString();
        string memory category = this.getNFTCategory(nftLevel[tokenId]);

        string memory json = string(
            abi.encodePacked(
                '{"name":"', name, '",',
                '"description":"', description, '",',
                '"attributes":[{"trait_type":"Impact Level","value":"', impactStr, '"},',
                '{"trait_type":"NFT Level","value":"', levelStr, '"},',
                '{"trait_type":"Category","value":"', category, '"}],',
                '"image":"', generateBase64Image(), '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function generateBase64Image() internal pure returns (string memory) {
        string memory svg = '<svg width="200" height="60" xmlns="http://www.w3.org/2000/svg"><style>'
                            'text { paint-order: stroke; stroke: white; stroke-width: 2px; fill: black; text-anchor: middle; dominant-baseline: central; }</style>'
                            '<defs><linearGradient id="gradient" x1="0%" x2="100%" y1="0%" y2="0%">'
                            '<stop offset="0%" stop-color="#00ff6e"/>'
                            '<stop offset="100%" stop-color="#f4774e"/></linearGradient></defs>'
                            '<rect width="100%" height="100%" rx="10" ry="10" fill="url(#gradient)"/>'
                            '<text x="50%" y="50%" font-size="21px">Chinonso</text>'
                            '</svg>';

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }
}