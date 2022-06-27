pragma solidity ^0.8.4;         // SPDX-License-Identifier: MIT
// pragma specifies the compiler version to be used for current solidity file

// ** minting NFT smart contract and its functionalities **

// with the help of openzeppelin we can import NFT functionality
import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721URIStorage{               // inherit URI storage n gives IPFS address to store the information
    using Counters for Counters.Counter;        // counters allows us to keep track of tokenIds used in the program
    Counters.Counter private _tokenIds;
    
    address contractAddress;                    // address of marketplace for NFTs to interact which is going to 
                                                // get deployed in config.js after we run the localhost
    // OBJ: give the NFT market the ability to transact with tokens
    // setApprovalForAll allows us to do that with contract address


     // initiating constructor to set up the contract address
     constructor(address marketplaceAddress) ERC721('KryptoBirdz', 'KBIRDZ'){  // ERC721 is inherited from abstract class of ERC721URIStorage
        contractAddress = marketplaceAddress;
    }

    function mintToken(string memory tokenURI) public returns(uint){
        _tokenIds.increment();      // miniting a token, thus we r incrementing tokenId
        uint256 newItemId = _tokenIds.current();    // current function inherited from Counters.sol 
        _mint(msg.sender,newItemId);
        
        _setTokenURI(newItemId, tokenURI);      // set the token URI: id and url
        
        //this function give the marketplace the approval to transact between users
        setApprovalForAll(contractAddress, true);  
        
        return newItemId;                   // mint the token and set it up for sale - return the id to do so
    }
}

