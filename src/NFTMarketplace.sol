// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Homework} from "./Homework.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace is Homework {
    address public owner;
    uint256 public constant FEE_PERCENT = 1;
    uint256 public totalFeesCollected;

    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 minPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool active;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(address => uint256) public pendingReturns;
    mapping(address => uint256) public pendingSellerProceeds;
    uint256 public auctionCount;

    event AuctionListed(
        uint256 indexed auctionId,
        address seller,
        uint256 minPrice
    );
    event NewBid(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionEnded(
        uint256 indexed auctionId,
        address winner,
        uint256 amount
    );

    constructor() {
        owner = msg.sender;
    }

    function listNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _duration
    ) external {
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
            "Not token owner"
        );
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        auctionCount++;
        auctions[auctionCount] = Auction({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            minPrice: _minPrice,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: 0,
            active: true
        });

        emit AuctionListed(auctionCount, msg.sender, _minPrice);
    }

    function placeBid(uint256 _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value >= auction.minPrice, "Below min price");
        require(msg.value > auction.highestBid, "Higher bid exists");

        address prevBidder = auction.highestBidder;
        uint256 prevBid = auction.highestBid;

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        if (prevBidder != address(0)) {
            pendingReturns[prevBidder] += prevBid;
        }

        emit NewBid(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Not ended yet");
        require(auction.active, "Already settled");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            uint256 fee = (auction.highestBid * FEE_PERCENT) / 100;
            uint256 sellerProceeds = auction.highestBid - fee;
            totalFeesCollected += fee;

            require(
                IERC721(auction.nftAddress).ownerOf(auction.tokenId) ==
                    address(this),
                "NFT not owned by contract"
            );
            IERC721(auction.nftAddress).safeTransferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );
            pendingSellerProceeds[auction.seller] += sellerProceeds;
        } else {
            require(
                IERC721(auction.nftAddress).ownerOf(auction.tokenId) ==
                    address(this),
                "NFT not owned by contract"
            );
            IERC721(auction.nftAddress).safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        }

        emit AuctionEnded(
            _auctionId,
            auction.highestBidder,
            auction.highestBid
        );
    }

    function withdrawRefund() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function withdrawSellerProceeds() external {
        uint256 amount = pendingSellerProceeds[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingSellerProceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function withdrawFees() external {
        require(msg.sender == owner, "Only owner");
        uint256 amount = totalFeesCollected;
        totalFeesCollected = 0;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }
}
