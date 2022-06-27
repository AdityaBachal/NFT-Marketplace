import {ethers} from 'ethers'       // import statements to build the project
import {useEffect , useState} from 'react'
import axios from 'axios'
import Web3Modal from 'web3modal'

import { nftaddress , nftmarketaddress } from '../config'

import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import KBMarket from '../artifacts/contracts/KBMarket.sol/KBMarket.json'

export default function Home() {
  const [nfts, setNFTs] = useState([])
  const [loadingState, setLoadingState] = useState('not-loaded')

  useEffect(() => {
    loadNFTs()
  }, [])

  async function loadNFTs(){
    // what we want to load:
    // ***provider, tokenContract, marketContract, data for our marketItems***


    const provider = new ethers.providers.JsonRpcProvider()
    const tokenContract = new ethers.Contract(nftaddress, NFT.abi, provider)
    const marketContract = new ethers.Contract(nftmarketaddress, KBMarket.abi , provider)
    const data = await marketContract.fetchMarketTokens()

    const items = await Promise.all(data.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      //  we want to get token meta data - json
      const meta = await axios.get(tokenUri)
      let price = ethers.utils.formatUnits(i.price.toString(), 'ether')
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        owner: i.owner,
        image: meta.data.image,
        name: meta.data.name,
        description: meta.data.description
      }
      return item
    })) 

    setNFTs(items)
    setLoadingState('loaded')
  }

  // function to buy NFTs from market

  async function buyNFT(nft){
    const web3Modal = new Web3Modal()
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner()
    const contract = new ethers.Contract(nftmarketaddress, KBMarket.abi , signer)

    const price = ethers.utils.parseUnits(nft.price.toString(),'ether')
    const transaction = await contract.createMarketSale(nftaddress, nft.tokenId ,{
      value: price
    })

    await transaction.wait()
    loadNFTs()
  }
  if(loadingState == 'loaded' && !nfts.length) return (<h1
    className='px-20 py-7 text-4x1 text-red-600'>No NFTs in market</h1>)

  return ( 
    <div className='flex justify-center'>
        <div className='px-4' style={{maxWidth: '1200px'}}>
            <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-10 pt-10'>
              {
                nfts.map((nft, i) => (
                  <div key={1} className='border shadow rounded-x1 overflow-hidden'>
                      <img src= {nft.image} />
                      <div className='p-4'>
                        <p style={{height: '50px' , color:'gold'}} className='text-4x1 font-semibold'>{
                            nft.name}</p>
                            <div style={{height:'72px', overflow:'hidden'}}>
                              <p className='text-red-500'>{nft.description}</p>

                              </div>

                        </div>
                        <div className='p-4 bg-black'>
                          <p className='text-3x-1 mb-2 font-bold text-white'>{nft.price} ETH</p>
                          <button className='w-full bg-blue-500 text-white font-bold py-3 px-12 rounded'
                          onClick={() => buyNFT(nft)}> Buy
                            
                          </button>

                        </div>
                  </div>
                ))
              }

            </div>
        </div>
    </div>
  )
}
