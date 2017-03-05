import PackageDescription

let package = Package(
    name: "couchDB",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", majorVersion: 1)
    ]
)
