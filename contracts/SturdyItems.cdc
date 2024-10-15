import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import HoodlumsMetadata from 0x1d7e57aa55817448
import ViewResolver from 0x1d7e57aa55817448

// SturdyItems
// NFT items for Sturdy! 
access(all) contract SturdyItems: ViewResolver, NonFungibleToken {

    // Event declarations
    access(all) event ContractInitialized()
    access(all) event AccountInitialized()
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
    access(all) event Purchased(buyer: Address, id: UInt64, price: UInt64)

    // Named paths
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    // The total number of Hoodlums minted
    access(all) var totalSupply: UInt64

    // Entitlement for Owner
    access(all) entitlement Owner

    // Hoodlums NFT definition
    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let typeID: UInt64
        access(all) let tokenURI: String
        access(all) let tokenTitle: String
        access(all) let tokenDescription: String
        access(all) let artist: String
        access(all) let secondaryRoyalty: String
        access(all) let platformMintedOn: String

        // Helper function to extract digits from a string
        access(all) fun extractDigits(from str: String): String {
            var digits: String = ""
            for char in str {
                if char >= "0" && char <= "9" {
                    digits = digits.concat(char)
                }
            }
            return digits
        }

        // Supported metadata views for the NFT
        access(all) view fun getViews(): [Type] {
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

        // Resolves metadata views for the NFT
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTView>():
                    let viewResolver = &self as &{ViewResolver.Resolver}
                    return MetadataViews.NFTView(
                        id: self.id,
                        uuid: self.uuid,
                        display: MetadataViews.getDisplay(viewResolver),
                        externalURL: MetadataViews.getExternalURL(viewResolver),
                        collectionData: MetadataViews.getNFTCollectionData(viewResolver),
                        collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver),
                        royalties: MetadataViews.getRoyalties(viewResolver),
                        traits: MetadataViews.getTraits(viewResolver)
                    )

                // Extract Hoodlum # from NFT Title and use in IPFS URL
                case Type<MetadataViews.Display>():
                    let hoodlumNumber = self.extractDigits(from: self.tokenTitle)

                    return MetadataViews.Display(
                        name: self.tokenTitle,
                        description: self.tokenDescription,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: "QmTPGjR5TN2QLMm6VN2Ux81NK955qqgvrjQkCwNDqW73fs",
                            path: "someHoodlum_".concat(hoodlumNumber).concat(".png")
                        )
                    )

                case Type<MetadataViews.ExternalURL>():
                    let url = "https://flowty.io/collection/"
                        .concat(SturdyItems.account.address.toString())
                        .concat("/SturdyItems/")
                        .concat(self.id.toString())

                    return MetadataViews.ExternalURL(url)

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SturdyItems.CollectionStoragePath,
                        publicPath: SturdyItems.CollectionPublicPath,
                        publicCollection: Type<&SturdyItems.Collection>(),
                        publicLinkedType: Type<&SturdyItems.Collection>(),
                        createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                            return <-SturdyItems.createEmptyCollection(nftType: Type<@NFT>())
                        })
                    )

                case Type<MetadataViews.NFTCollectionDisplay>():
                    let thumbnail = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(cid: "QmYQPsikmJxRAtCFGTa3coUoG6bZqduyckAwodUQ35T8p9", path: nil),
                        mediaType: "image/jpeg"
                    )
                    let banner = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(cid: "QmPqVFuM2d4bSqFCjTddajaSb7AVYpDrRJuw3BeE8s1cRJ", path: nil),
                        mediaType: "image/jpeg"
                    )

                    return MetadataViews.NFTCollectionDisplay(
                        name: "Hoodlums",
                        description: "Hoodlums NFT is a generative art project featuring 5,000 unique Hoodlum PFPs, crafted from hand-drawn traits by renowned memelord Somehoodlum. Created for creatives, by creatives, the project is owned and operated by Hoodlums holders through Hoodlums DAO. Hoodlums is the first PFP on the Flow Blockchain, minted in September 2021.",
                        externalURL: MetadataViews.ExternalURL("https://www.hoodlums.io/"),
                        squareImage: thumbnail,
                        bannerImage: banner,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://x.com/HoodlumsNFT"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/ah2jynWk")
                        }
                    )

                case Type<MetadataViews.Traits>():
                    return HoodlumsMetadata.getMetadata(tokenID: self.id)

                case Type<MetadataViews.Medias>():
                    let hoodlumNumber = self.extractDigits(from: self.tokenTitle)
                    let medias: [MetadataViews.Media] = [
                        MetadataViews.Media(
                            file: MetadataViews.IPFSFile(
                                cid: "QmTPGjR5TN2QLMm6VN2Ux81NK955qqgvrjQkCwNDqW73fs",
                                path: "someHoodlum_".concat(hoodlumNumber).concat(".png")
                            ),
                            mediaType: "image/png"
                        )
                    ]
                    return MetadataViews.Medias(medias)

                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([
                        MetadataViews.Royalty(
                            receiver: getAccount(HoodlumsMetadata.sturdyRoyaltyAddress)
                                .getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver),
                            cut: HoodlumsMetadata.sturdyRoyaltyCut,
                            description: "Hoodlums DAO Royalty"
                        ),
                        MetadataViews.Royalty(
                            receiver: getAccount(HoodlumsMetadata.artistRoyaltyAddress)
                                .getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver),
                            cut: HoodlumsMetadata.artistRoyaltyCut,
                            description: "Somehoodlum Royalty"
                        )
                    ])

                default:
                    return nil
            }
        }

        init(
            initID: UInt64, 
            initTypeID: UInt64, 
            initTokenURI: String, 
            initTokenTitle: String, 
            initTokenDescription: String, 
            initArtist: String, 
            initSecondaryRoyalty: String,
            initPlatformMintedOn: String
        ) {
            self.id = initID
            self.typeID = initTypeID
            self.tokenURI = initTokenURI
            self.tokenTitle = initTokenTitle
            self.tokenDescription = initTokenDescription
            self.artist = initArtist
            self.secondaryRoyalty = initSecondaryRoyalty
            self.platformMintedOn = initPlatformMintedOn
        }
    }

    // Public interface for a SturdyItems collection
    access(all) resource interface SturdyItemsCollectionPublic: NonFungibleToken.Collection {
        access(all) fun deposit(token: @{NonFungibleToken.NFT})
        access(all) view fun borrowSturdyItem(id: UInt64): &SturdyItems.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow SturdyItem reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection of SturdyItems owned by an account
    access(all) resource Collection: SturdyItemsCollectionPublic {
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // Withdraws an NFT from the collection
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        // Deposits an NFT into the collection
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token as! @SturdyItems.NFT
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        // Returns all IDs in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Borrows an NFT reference from the collection
        access(all) view fun borrowNFT(id: UInt64): &NonFungibleToken.NFT? {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // Borrows a SturdyItem reference from the collection
        access(all) view fun borrowSturdyItem(id: UInt64): &SturdyItems.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
                return ref as! &SturdyItems.NFT
            }
            return nil
        }

        // Borrows a view resolver reference for an NFT
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
            let nft = (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            return nft
        }

        // Supported NFT types
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {
                Type<@SturdyItems.NFT>(): true
            }
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SturdyItems.NFT>()
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    // NFTMinter resource for minting new NFTs
    access(all) resource NFTMinter {
        access(Owner) fun mintNFT(
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
            emit Minted(
                id: SturdyItems.totalSupply, 
                typeID: typeID, 
                tokenURI: tokenURI, 
                tokenTitle: tokenTitle, 
                tokenDescription: tokenDescription,
                artist: artist, 
                secondaryRoyalty: secondaryRoyalty, 
                platformMintedOn: platformMintedOn
            )
            recipient.deposit(token: <-create NFT(
                initID: SturdyItems.totalSupply, 
                initTypeID: typeID, 
                initTokenURI: tokenURI,
                initTokenTitle: tokenTitle,
                initTokenDescription: tokenDescription,
                initArtist: artist,
                initSecondaryRoyalty: secondaryRoyalty,
                initPlatformMintedOn: platformMintedOn
            ))
        }
    }

    // Fetches an NFT from an account's collection
    access(all) fun fetch(_ from: Address, itemID: UInt64): &SturdyItems.NFT? {
        let collection = getAccount(from)
            .getCapability<&{NonFungibleToken.CollectionPublic}>(SturdyItems.CollectionPublicPath)
            .borrow()
            ?? panic("Couldn't get collection")
        let sturdyCollection = collection as! &SturdyItems.Collection
        return sturdyCollection.borrowSturdyItem(id: itemID)
    }

    // Resolves a metadata view for the contract
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: SturdyItems.CollectionStoragePath,
                    publicPath: SturdyItems.CollectionPublicPath,
                    publicCollection: Type<&SturdyItems.Collection>(),
                    publicLinkedType: Type<&SturdyItems.Collection>(),
                    createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                        return <-SturdyItems.createEmptyCollection(nftType: Type<@NFT>())
                    })
                )

            case Type<MetadataViews.NFTCollectionDisplay>():
                let thumbnail = MetadataViews.Media(
                    file: MetadataViews.IPFSFile(cid: "QmYQPsikmJxRAtCFGTa3coUoG6bZqduyckAwodUQ35T8p9", path: nil),
                    mediaType: "image/jpeg"
                )
                let banner = MetadataViews.Media(
                    file: MetadataViews.IPFSFile(cid: "QmPqVFuM2d4bSqFCjTddajaSb7AVYpDrRJuw3BeE8s1cRJ", path: nil),
                    mediaType: "image/jpeg"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Hoodlums",
                    description: "Hoodlums NFT is a generative art project featuring 5,000 unique Hoodlum PFPs.",
                    externalURL: MetadataViews.ExternalURL("https://www.hoodlums.io/"),
                    squareImage: thumbnail,
                    bannerImage: banner,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/HoodlumsNFT"),
                        "discord": MetadataViews.ExternalURL("https://discord.gg/ah2jynWk")
                    }
                )
            default:
                return nil
        }
    }

    // Returns all metadata views implemented by the contract
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.ExternalURL>()
        ]
    }

    // Creates an empty collection
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        pre {
            nftType == Type<@NFT>(): "Incorrect NFT type provided"
        }
        return <- create Collection()
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
// DG4L
