# swift-poloniex-portfolio
Command-line executable to load a portfolio of cryptocoins from Poloniex

This executable uses the Poloniex API to load your portfolio and open orders, and report the total value in BTC and USD. It can be used with an app like [Bitbar](https://getbitbar.com) to make it easy to quickly check on your portfolio.

## Requirements

You must have the Xcode command-line tools and Swift 3 installed.

`xcode-select --install`

The executable also uses your [Poloniex API keys](https://poloniex.com/apiKeys) to load data from your account. Be careful with those keys, as they can be used to make trades and transfers from your account. Put the key and secret in a json file in this format:

```
{
    "API_KEY": "xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx",
    "API_SECRET": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx..."
}
```

## Building

`swift build`

## Running

`.build/debug/poloniex-portfolio <path to keys file>`
