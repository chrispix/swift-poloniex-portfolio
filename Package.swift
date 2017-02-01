import PackageDescription

let package = Package(
    name: "poloniex",
    targets: [Target(name: "crypto", dependencies:["objc"]),
              Target(name: "poloniex", dependencies:["crypto"])]
)
