import PackageDescription

let package = Package(
    name: "poloniex-portfolio",
    targets: [Target(name: "crypto", dependencies:["objc"]),
              Target(name: "poloniex", dependencies:["crypto"]),
              Target(name: "poloniex-portfolio", dependencies:["poloniex"])],
    dependencies: [
        .Package(url: "https://github.com/oarrabi/Guaka.git", majorVersion: 0)
    ]
)
