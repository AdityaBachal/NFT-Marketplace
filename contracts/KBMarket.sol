pragma solidity ^0.8.4;         // SPDX-License-Identifier: MIT

// ** seting up Marketplace smart contract and its functionalities **

// with the help of openzeppelin we can import NFT functionality
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/* ** file objectives ** 
   number of items mining, number of transactions, tokens that have not been sold
   keep track of total number - tokenId
   arrays need to know the length - help to keep track for arrays */

// security against transactions for multiple requests
import 'hardhat/console.sol';

contract KBMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;

    // determine  who is the owner of the contract
    // charge a listing fee so the owner makes a commission

    address payable owner;      // payable ensures that u can send n receive ETH among the users
    // we are deploying to matic the API is the same so you can use ether the same as matic
    // they both have 18 decimal 
    // 0.045 is in the cents
    uint256 listingPrice = 0.045 ether;     // gas fee which will appear on meta mask, we can customize as per  
                                            // our requirement

    constructor(){
        // set the owner 
        owner = payable(msg.sender);
    }

    
    // declaring structure to take care of our market tokens
    struct MarketToken {            // structs to store data of different datatype
        uint itemId;                // structs can act like objects as in solidity we cant create objects
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    
    // mapping here just creates a db which we can further access it in different ways
    // using token MarketToken (struct) we can access all the values in the above structure
    mapping(uint256 => MarketToken) private idToMarketToken;// tokenId return which MarketToken - fetch which one it is

    // listen to events from front end applications 
    // useful for client side applications
    event MarketTokenMinted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // this function returns the listingPrice (for frontend purpose)
    function getListingPrice() public view returns (uint256){
        return listingPrice;  // we have set up our listing price above as 0.045 ETH
    }

    // two functions to interact with contract
    // 1. create a market item to put it up for sale
    // 2. create a market sale for buying and selling between parties


    // this is the first function
    function makeMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    )
    public payable nonReentrant{        // nonReentrant is a modifier to protect us from multiple requests
 

    require(price>0,'Price must be atleast one way');
    // security measures which will also make sure that we wont go on minting endlessly
    require(msg.value == listingPrice , 'Price must be equal to listing price' ); 

    _tokenIds.increment();                  // _tokenIds is a counter   
    uint itemId = _tokenIds.current();      

    // putting it up for sale - bool - no owner 
    idToMarketToken[itemId] = MarketToken(  // we can update the information which we r going to pass through struct
        itemId,                    // things which we r going to update
        nftContract,
        tokenId,
        payable(msg.sender),
        payable(address(0)),        // no owner yet coz we r minting the NFT first
        price,
        false                       // set to false coz we havent sold it yet
    );

    // NFT Transaction

    // transferFrom transfers the tokens from an owners acc to the recievers acc
    IERC721(nftContract).transferFrom(msg.sender,address(this), tokenId);

    emit MarketTokenMinted(         // we use emit as it helps to differentiate the functions from an event 
        itemId,             
        nftContract,
        tokenId,
        msg.sender,
        address(0),
        price,
        false
    );
    }
    
    // function to conduct transaction and market sales
    function createMarketSale(
        address nftContract,
        uint itemId)
        public payable nonReentrant {
            uint price = idToMarketToken[itemId].price;         // updating mapping
            uint tokenId  = idToMarketToken[itemId].tokenId;
            require(msg.value == price , 'Please submit the asking price in order to continue');

           // transfer the amount to the seller  
           idToMarketToken[itemId].seller.transfer(msg.value);  
           
           // transfer the token from contract address to the buyer
           IERC721(nftContract).transferFrom(address(this), msg.sender , tokenId); 
           idToMarketToken[itemId].owner = payable(msg.sender);
           idToMarketToken[itemId].sold = true;
           _tokensSold.increment();

           // transfer it to front end
           payable(owner).transfer(listingPrice);
        }
    
    // second function
     // function to fetchMarketItems - minting, buying ans selling
     // return the number of unsold items

     function fetchMarketTokens() public view returns(MarketToken[] memory){    // using memory as we have used struct
         uint itemCount = _tokenIds.current();
         uint unsoldItemCount = _tokenIds.current() - _tokensSold.current();
         uint currentIndex = 0;

         // looping over the number of items created - if nummber has not been sold populate the array
         // i.e. all the unsold NFTs will be shown back in the marketplace
         MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        for(uint i = 0; i<itemCount;i++){
            if(idToMarketToken[i+1].owner == address(0)){
                uint currentId = i+1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
     } 

    // return nfts that the user has purchased 
    // displays NFTs bought by the user in MyNFT section
    function fecthMyNFTs() public view returns (MarketToken[] memory){
        uint totalItemCount = _tokenIds.current();
        // a second counter for each individual user
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i=0;i<totalItemCount;i++){
            if(idToMarketToken[i+1].owner == msg.sender){
            itemCount += 1;
            } 
        }
    
    // second loop to loop through the amount you have purchased with itemcount
    // check to see if the owner address is equal to msg.sender

    MarketToken[] memory items = new MarketToken[](itemCount);  
    for(uint i=0;i<totalItemCount;i++){
        if(idToMarketToken[i+1].owner == msg.sender){
            uint currentId = idToMarketToken[i+1].itemId;
            // current array 
            MarketToken storage currentItem = idToMarketToken[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1; 
        }
        }
        return items;
    }

    // function for returning an array of minted nfts
    // used for dashboard display purpose
    function fetchItemsCreated() public view returns(MarketToken[] memory){
        // instead of .owner it will be the .seller
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0 ;
        uint currentIndex = 0;

        for(uint i=0;i<totalItemCount;i++){
            if(idToMarketToken[i+1].seller == msg.sender){
            itemCount += 1;
            } 
        }
    
    // second loop to loop through the amount you have purchased with itemcount
    // check to see if the owner address is equal to msg.sender

    MarketToken[] memory items = new MarketToken[](itemCount);  
    for(uint i=0;i<totalItemCount;i++){
        if(idToMarketToken[i+1].seller == msg.sender){
            uint currentId = idToMarketToken[i+1].itemId;
            MarketToken storage currentItem = idToMarketToken[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1; 
        }
    }
    return items;
    }
}