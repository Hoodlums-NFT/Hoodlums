import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "HoodlumsMetadata"
import "ViewResolver"

// SturdyItems
// NFT items for Sturdy!
//
access(all) contract SturdyItems: ViewResolver {

    // Events
    //
    access(all) event ContractInitialized()
    access(all) event AccountInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) event Minted(id: UInt64, 
    	typeID: UInt64, 
		tokenURI: String, 
		tokenTitle: String, 
		tokenDescription: String,
		artist: String, 
		secondaryRoyalty: String, 
		platformMintedOn: String)
    access(all) event Purchased(buyer: Address, id: UInt64, price: UInt64)

    // Named Paths
    //
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of SturdyItems that have been minted
    //
    access(all) var totalSupply: UInt64

    // NFT
    // A Sturdy Item as an NFT
    //
    access(all) resource NFT: NonFungibleToken.NFT {
        // The token's ID
        access(all) let id: UInt64
        // The token's type, e.g. 3 == Hat
        access(all) let typeID: UInt64
        // Token URI
        access(all) let tokenURI: String
        // Token Title
        access(all) let tokenTitle: String
        // Token Description
        access(all) let tokenDescription: String
        // Artist info
        access(all) let artist: String
        // Secondary Royalty
        access(all) let secondaryRoyalty: String
        // Platform Minted On
        access(all) let platformMintedOn: String
        // Token Price
        // access(all) let price: UInt64

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

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            let metadata = HoodlumsMetadata.getMetadata(tokenID: self.id)
            let thumbnailCID = metadata!["thumbnailCID"] != nil ? metadata!["thumbnailCID"]! : metadata!["imageCID"]!
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
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.tokenTitle,
                        description: self.tokenDescription,
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://ipfs.io/ipfs/".concat(thumbnailCID)
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://ipfs.io/ipfs/".concat(thumbnailCID))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SturdyItems.CollectionStoragePath,
                        publicPath: SturdyItems.CollectionPublicPath,
                        publicCollection: Type<&SturdyItems.Collection>(),
                        publicLinkedType: Type<&SturdyItems.Collection>(),
                        createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                            return <-SturdyItems.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(cid: "bafkreigos42bix6eyvdqwgsbpwwpiemttt772g7ql5khsrutzrfflc4bpq", path: nil),
                        mediaType: "image/jpeg"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Hoodlums",
                        description: "",
                        externalURL: MetadataViews.ExternalURL("https://hoodlumsnft.com/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    var metadata = HoodlumsMetadata.getMetadata(tokenID: self.id)
                    return metadata
                case Type<MetadataViews.Medias>():
                    let medias: [MetadataViews.Media] = [];
                    let imageCID = metadata!["imageCID"]
                    if imageCID != nil {
                        medias.append(
                            MetadataViews.Media(
                                file: MetadataViews.HTTPFile(
                                    url: "https://ipfs.io/ipfs/".concat(thumbnailCID)
                                ),
                                mediaType: "image/jpeg"
                            )
                        )
                    }
                    return MetadataViews.Medias(medias)
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        [
                            MetadataViews.Royalty(
                            receiver: getAccount(HoodlumsMetadata.sturdyRoyaltyAddress)
                                    .capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver),
                                cut: HoodlumsMetadata.sturdyRoyaltyCut,
                                description: "Sturdy Royalty"
                            ),
                            MetadataViews.Royalty(
                                receiver: getAccount(HoodlumsMetadata.artistRoyaltyAddress)
                                    .capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver),
                                cut: HoodlumsMetadata.artistRoyaltyCut,
                                description: "Artist Royalty"
                            )
                        ]
                    )
            }
            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- SturdyItems.createEmptyCollection()
        }

        // initializer
        //
        init(initID: UInt64, 
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

    // This is the interface that users can cast their SturdyItems Collection as
    // to allow others to deposit SturdyItems into their Collection. It also allows for reading
    // the details of SturdyItems in the Collection.
    access(all) resource interface SturdyItemsCollectionPublic: NonFungibleToken.Collection {
        access(all) fun deposit(token: @{NonFungibleToken.NFT})
        access(all) view fun borrowSturdyItem(id: UInt64): &SturdyItems.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow SturdyItem reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of SturdyItem NFTs owned by an account
    //
    access(all) resource Collection: SturdyItemsCollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token <- token as! @SturdyItems.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
        }

        // borrowSturdyItem
        // Gets a reference to an NFT in the collection as a SturdyItem,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the SturdyItem.
        //
        access(all) view fun borrowSturdyItem(id: UInt64): &SturdyItems.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
                return ref as! &SturdyItems.NFT
            } else {
                return nil
            }
        }


        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver} {
            let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
            return nft as! &SturdyItems.NFT
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {
                Type<@SturdyItems.NFT>(): true
            }
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@SturdyItems.NFT>()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
        emit AccountInitialized()
        return <- create Collection()
    }

    // purchased
    // Remain price information
    //
    access(all) fun purchased(recipient: Address, tokenID: UInt64, price: UInt64): UInt64 {
        emit Purchased(buyer: recipient, id: tokenID, price: price)
        return tokenID
    }


    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	access(all) resource NFTMinter {

		// mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        //
        // price: UInt64
        // price: price
        // initPrice: price
		access(all) fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, 
			typeID: UInt64, 
			tokenURI: String, 
			tokenTitle: String, 
			tokenDescription: String, 
		 	artist: String, 
		 	secondaryRoyalty: String,  
		 	platformMintedOn: String
        ) {
            SturdyItems.totalSupply = SturdyItems.totalSupply + (1 as UInt64)
            emit Minted(id: SturdyItems.totalSupply, 
            	typeID: typeID, 
            	tokenURI: tokenURI, 
            	tokenTitle: tokenTitle, 
            	tokenDescription: tokenDescription,
            	artist: artist, 
            	secondaryRoyalty: secondaryRoyalty, 
            	platformMintedOn: platformMintedOn
            )

			// deposit it in the recipient's account using their reference
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

    // fetch
    // Get a reference to a SturdyItem from an account's Collection, if available.
    // If an account does not have a SturdyItems.Collection, panic.
    // If it has a collection but does not contain the itemId, return nil.
    // If it has a collection and that collection contains the itemId, return a reference to that.
    //
    access(all) fun fetch(_ from: Address, itemID: UInt64): &SturdyItems.NFT? {
        let collection = getAccount(from).capabilities
            .get<&{NonFungibleToken.Collection}>(SturdyItems.CollectionPublicPath)
            .borrow()
            ?? panic("Couldn't get collection")
        let sturdyCollection = collection as! &SturdyItems.Collection
        // We trust SturdyItems.Collection.borowSturdyItem to get the correct itemID
        // (it checks it before returning it).
        return sturdyCollection.borrowSturdyItem(id: itemID)
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                        storagePath: SturdyItems.CollectionStoragePath,
                        publicPath: SturdyItems.CollectionPublicPath,
                        publicCollection: Type<&SturdyItems.Collection>(),
                        publicLinkedType: Type<&SturdyItems.Collection>(),
                        createEmptyCollectionFunction: (fun (): @{NonFungibleToken.Collection} {
                            return <-SturdyItems.createEmptyCollection()
                        })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(cid: "bafkreigos42bix6eyvdqwgsbpwwpiemttt772g7ql5khsrutzrfflc4bpq", path: nil),
                        mediaType: "image/jpeg"
                    )
                return MetadataViews.NFTCollectionDisplay(
                        name: "Hoodlums",
                        description: "",
                        externalURL: MetadataViews.ExternalURL("https://www.flowty.io/collection/0x427ceada271aa0b1/SturdyItems"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://x.com/HoodlumsNFT")
                        }
                    )
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.ExternalURL>()
        ]
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/SturdyItemsCollection
        self.CollectionPublicPath = /public/SturdyItemsCollection
        self.MinterStoragePath = /storage/SturdyItemsMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
	}
}
