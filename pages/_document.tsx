import Document, { Head, Html, Main, NextScript } from "next/document";

class MyDocument extends Document {
  render() {
    return (
      <Html lang="en">
        <Head>
          <link rel="icon" href="/favicon.ico" />
          <meta
            name="description"
            content="Feel free, be cool."
          />
          <meta property="og:site_name" content="Trapnest" />
          <meta
            property="og:description"
            content="Feel free, be cool."
          />
          <meta property="og:title" content="Trapnest" />
          <meta name="twitter:card" content="Trapnest" />
          <meta name="twitter:title" content="Trapnest" />
          <meta
            name="twitter:description"
            content="Feel free, be cool."
          />
        </Head>
        <body className="bg-black antialiased">
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}

export default MyDocument;
