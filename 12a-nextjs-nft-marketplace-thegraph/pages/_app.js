import Head from 'next/head';
import Header from '../components/Header';
import Footer from '../components/Footer';
import '../styles/globals.css';
import '@rainbow-me/rainbowkit/styles.css';
import 'react-toastify/dist/ReactToastify.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import '../styles/antd.dark.css';

import {
  getDefaultWallets,
  RainbowKitProvider,
  darkTheme,
} from '@rainbow-me/rainbowkit';
import { chain, configureChains, createClient, WagmiConfig } from 'wagmi';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import {
  ApolloClient,
  InMemoryCache,
  ApolloLink,
  ApolloProvider,
  createHttpLink,
} from '@apollo/client';
import { MultiAPILink } from '@habx/apollo-multi-endpoint-link';
import { onError } from '@apollo/client/link/error';
import { ToastContainer } from 'react-toastify';

const defaultChains = [
  { ...chain.goerli },
  { ...chain.polygonMumbai },
  {
    ...chain.arbitrumGoerli,
    iconUrl: 'https://arbitrum.io/favicon.ico',
  },
];

const { chains, provider, webSocketProvider } = configureChains(defaultChains, [
  alchemyProvider({ apiKey: process.env.ALCHEMY_API_KEY }),
  publicProvider(),
]);

const { connectors } = getDefaultWallets({
  appName: 'NFT Marketplace - The Graph',
  chains,
});

const wagmiClient = createClient({
  provider,
  webSocketProvider,
  autoConnect: true,
  connectors,
});

const errorLink = onError(({ graphQLErrors, networkError }) => {
  if (graphQLErrors) {
    graphQLErrors.map(({ message, locations, path }) =>
      console.log(
        `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`,
      ),
    );
  }
  if (networkError) console.log(`[Network error]: ${networkError}`);
});
console.log(process.env.NEXT_PUBLIC_SUBGRAPH_URL_GOERLI);
console.log(process.env.NEXT_PUBLIC_SUBGRAPH_URL_MUMBAI);
const apolloClient = new ApolloClient({
  cache: new InMemoryCache(),
  link: ApolloLink.from([
    errorLink,
    new MultiAPILink({
      endpoints: {
        goerli: process.env.NEXT_PUBLIC_SUBGRAPH_URL_GOERLI,
        mumbai: process.env.NEXT_PUBLIC_SUBGRAPH_URL_MUMBAI,
        arbitrumGoerli: process.env.NEXT_PUBLIC_SUBGRAPH_URL_ARBITRUM_GOERLI,
      },
      defaultEndpoint: process.env.NEXT_PUBLIC_SUBGRAPH_URL_GOERLI,
      createHttpLink: () => createHttpLink(),
      httpSuffix: '',
    }),
    // createHttpLink({
    //   uri: process.env.NEXT_PUBLIC_SUBGRAPH_URL_GOERLI,
    // }),
  ]),
});

function MyApp({ Component, pageProps }) {
  return (
    <div id='container'>
      <Head>
        <title>NFT Marketplace - TheGraph</title>
        <meta name='description' content='Generated by create next app' />
        <link rel='icon' href='/favicon.ico' />
      </Head>

      <WagmiConfig client={wagmiClient}>
        <RainbowKitProvider
          chains={chains}
          modalSize={{
            smallScreen: 'compact',
            largeScreen: 'wide',
          }}
          theme={darkTheme({
            accentColor: 'rgb(var(--alt-color))',
            accentColorForeground: '#fff',
            borderRadius: 'small',
            fontStack: 'rounded',
            overlayBlur: 'small',
          })}
        >
          <ApolloProvider client={apolloClient}>
            <div className='page'>
              <Header />
              <Component {...pageProps} />
              <Footer />
            </div>
          </ApolloProvider>
        </RainbowKitProvider>
      </WagmiConfig>
      <ToastContainer
        theme='colored'
        progressStyle={{ background: '#fff' }}
        position={'bottom-right'}
      />
    </div>
  );
}

export default MyApp;
