import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import HoodlumsMetadata from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448

// "SturdyItems" Contract
access(all) contract SturdyItems: ViewResolver, NonFungibleToken {

    // Events
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(
        id: UInt64, 
        typeID: UInt64, 
        tokenURI: String, 
        tokenTitle: String, 
        tokenDescription: String,
        artist: String, 
        secondaryRoyalty: String, 
        platformMintedOn: String
    )

    // Storage paths
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    // Track total minted NFTs
    access(all) var totalSupply: UInt64

    // NFT resource definition
    access(all) resource NFT: NonFungibleToken.NFT {
        pub let id: UInt64
        pub let typeID: UInt64
        pub let tokenURI: String
        pub let tokenTitle: String
        pub let tokenDescription: String
        pub let artist: String
        pub let secondaryRoyalty: String
        pub let platformMintedOn: String

        // Constructor for NFT resource
        init(
            id: UInt64, 
            typeID: UInt64, 
            tokenURI: String, 
            tokenTitle: String, 
            tokenDescription: String, 
            artist: String, 
            secondaryRoyalty: String, 
            platformMintedOn: String
        ) {
            self.id = id
            self.typeID = typeID
            self.tokenURI = tokenURI
            self.tokenTitle = tokenTitle
            self.tokenDescription = tokenDescription
            self.artist = artist
            self.secondaryRoyalty = secondaryRoyalty
            self.platformMintedOn = platformMintedOn
        }

        // Helper function to extract digits from a string 
        pub fun getLumNum(from str: String): String {
            var digits: String = ""
            for char in str {
                if char >= "0" && char <= "9" {
                    digits = digits.concat(char)
                }
            }
            return digits
        }

        // Supported Metadata Views
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTView>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Medias>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        // Resolve metadata views
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTView>():
                    return MetadataViews.NFTView(
                        id: self.id,
                        uuid: self.uuid,
                        display: MetadataViews.Display(
                            name: self.tokenTitle,
                            description: self.tokenDescription,
                            thumbnail: MetadataViews.IPFSFile(
                                cid: "QmTPGjR5TN2QLMm6VN2Ux81NK955qqgvrjQkCwNDqW73fs",
                                path: self.getLumNum(from: self.tokenTitle).concat(".png")
                            )
                        ),
                        externalURL: MetadataViews.ExternalURL(
                            "https://flowty.io/collection/".concat(SturdyItems.account.address.toString())
                                .concat("/SturdyItems/").concat(self.id.toString())
                        )
                    )

                case Type<MetadataViews.Display>():
                    let hoodlumNumber = self.getLumNum(from: self.tokenTitle)
                    return MetadataViews.Display(
                        name: self.tokenTitle,
                        description: self.tokenDescription,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: "QmTPGjR5TN2QLMm6VN2Ux81NK955qqgvrjQkCwNDqW73fs",
                            path: "someHoodlum_".concat(hoodlumNumber).concat(".png")
                        )
                    )

                default:
                    return nil
            }
        }
    }

    // NFT collection resource
    access(all) resource Collection: NonFungibleToken.Collection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        // Withdraw an NFT by ID
        pub fun withdraw(id: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: id) ?? panic("NFT not found")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        // Deposit an NFT into the collection
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let id = token.id
            self.ownedNFTs[id] <-! token
            emit Deposit(id: id, to: self.owner?.address)
        }

        // Get all NFT IDs in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
    }

    // NFT Minter resource for creating new NFTs
    access(all) resource NFTMinter {
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            typeID: UInt64, 
            tokenURI: String, 
            tokenTitle: String, 
            tokenDescription: String, 
            artist: String, 
            secondaryRoyalty: String, 
            platformMintedOn: String
        ) {
            SturdyItems.totalSupply = SturdyItems.totalSupply + 1
            let newID = SturdyItems.totalSupply

            let nft <- create NFT(
                id: newID, 
                typeID: typeID, 
                tokenURI: tokenURI, 
                tokenTitle: tokenTitle, 
                tokenDescription: tokenDescription, 
                artist: artist, 
                secondaryRoyalty: secondaryRoyalty, 
                platformMintedOn: platformMintedOn
            )

            recipient.deposit(token: <-nft)
            emit Minted(
                id: newID, 
                typeID: typeID, 
                tokenURI: tokenURI, 
                tokenTitle: tokenTitle, 
                tokenDescription: tokenDescription, 
                artist: artist, f
                secondaryRoyalty: secondaryRoyalty, 
                platformMintedOn: platformMintedOn
            )
        }
    }

    // Create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <-create Collection()
    }

    // Contract initializer
    init() {
        self.CollectionStoragePath = /storage/SturdyItemsCollection
        self.CollectionPublicPath = /public/SturdyItemsCollection
        self.MinterStoragePath = /storage/SturdyItemsMinter

        self.totalSupply = 0

        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}







//DG4L
