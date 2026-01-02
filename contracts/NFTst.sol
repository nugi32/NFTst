// contracts/NFTst.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTst is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Listing {
        uint256 price;
        address seller;
        string description;
        string category;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) public creationTime;
    mapping(uint256 => uint256) public viewCount;
    uint256 public constant MINT_FEE = 0.01 ether;
    uint256 public constant ROYALTY_FEE = 250; // 2.5%

    event NFTMinted(uint256 indexed tokenId, address indexed creator, string tokenURI, uint256 creationTime);
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price, string description, string category);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId, address indexed seller);
    event NFTViewed(uint256 indexed tokenId, uint256 viewCount);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);

    constructor() ERC721("NFTst", "NFTS") {
        _transferOwnership(msg.sender);
    }

    function mint(string memory uri) public payable returns (uint256) {
        require(msg.value >= MINT_FEE, "Insufficient minting fee");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
        _creators[newTokenId] = msg.sender;
        creationTime[newTokenId] = block.timestamp;

        emit NFTMinted(newTokenId, msg.sender, uri, block.timestamp);

        if (msg.value > MINT_FEE) {
            payable(msg.sender).transfer(msg.value - MINT_FEE);
        }

        return newTokenId;
    }

    function listForSale(uint256 tokenId, uint256 price, string memory description, string memory category) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than 0");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(category).length > 0, "Category cannot be empty");

        listings[tokenId] = Listing(price, msg.sender, description, category);
        _transfer(msg.sender, address(this), tokenId);
        emit NFTListed(tokenId, msg.sender, price, description, category);
    }

    function buyNFT(uint256 tokenId) public payable {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        address seller = listing.seller;
        address creator = _creators[tokenId];
        uint256 royaltyAmount = (listing.price * ROYALTY_FEE) / 10000;
        uint256 sellerAmount = listing.price - royaltyAmount;

        delete listings[tokenId];
        _transfer(address(this), msg.sender, tokenId);

        payable(seller).transfer(sellerAmount);
        if (royaltyAmount > 0 && creator != address(0)) {
            payable(creator).transfer(royaltyAmount);
        }
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }

        emit NFTSold(tokenId, msg.sender, seller, listing.price);
    }

    function cancelListing(uint256 tokenId) public {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT not listed");
        require(listing.seller == msg.sender, "Not the seller");

        delete listings[tokenId];
        _transfer(address(this), msg.sender, tokenId);
        emit NFTUnlisted(tokenId, msg.sender);
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(listings[tokenId].price == 0, "NFT is listed for sale");

        delete listings[tokenId];
        delete _tokenURIs[tokenId];
        delete _creators[tokenId];
        delete creationTime[tokenId];
        delete viewCount[tokenId];

        _burn(tokenId);
        emit NFTBurned(tokenId, msg.sender);
    }

    function viewNFT(uint256 tokenId) public {
        try this.ownerOf(tokenId) returns (address) {
            // Token exists if ownerOf doesn't revert
        } catch {
            revert("Token does not exist");
        }
        viewCount[tokenId]++;
        emit NFTViewed(tokenId, viewCount[tokenId]);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}