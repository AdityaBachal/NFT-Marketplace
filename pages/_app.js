import '../styles/globals.css'
import './app.css'
import Link from 'next/link'

// ** home page display **
function KryptoBirdMarketplace({Component, pageProps}){
  return(
    <div>
      <nav className='border-b p-6' style={{backgroundColor:'#4f46e5'}}>
        <p className='text-4x1 font-bold text-white'>KryptoBird Marketplace</p>
        <div className='flex mt-4 justify-center'>
          <Link href='/'>
            <a className='mr-4 text-white'>
              Main Marketplace
            </a>
          </Link>
          <Link href='/mint-item'>
            <a className='mr-6 text-white'>
              Mint Tokens
            </a>
          </Link>
          <Link href='/my-nfts'>
            <a className='mr-6 text-white'>
              My NFTs
            </a>
          </Link>
          <Link href='/account-dashboard'>
            <a className='mr-6 text-white'>
             Account Dashboard
            </a>
          </Link>
        </div>
      </nav>
      <Component {...pageProps} />
    </div>
  )
}

export default KryptoBirdMarketplace
