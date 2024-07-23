access(all) contract HoodlumsMetadata {

  access(all) event ContractInitialized()
  access(all) event MetadataSetted(tokenID: UInt64, metadata: {String: String})

  access(all) let AdminStoragePath: StoragePath

  access(self) let metadata: {UInt64: {String: String}}
  access(all) var sturdyRoyaltyAddress: Address
  access(all) var artistRoyaltyAddress: Address
  access(all) var sturdyRoyaltyCut: UFix64
  access(all) var artistRoyaltyCut: UFix64

  access(all) entitlement MetadataAdmin

  access(all) resource Admin {
    access(MetadataAdmin) fun setMetadata(tokenID: UInt64, metadata: {String: String}) {
      HoodlumsMetadata.metadata[tokenID] = metadata;
      emit MetadataSetted(tokenID: tokenID, metadata: metadata)
    }

    access(MetadataAdmin) fun setSturdyRoyaltyAddress(sturdyRoyaltyAddress: Address) {
      HoodlumsMetadata.sturdyRoyaltyAddress = sturdyRoyaltyAddress;
    }

    access(MetadataAdmin) fun setArtistRoyaltyAddress(artistRoyaltyAddress: Address) {
      HoodlumsMetadata.artistRoyaltyAddress = artistRoyaltyAddress;
    }

    access(MetadataAdmin) fun setSturdyRoyaltyCut(sturdyRoyaltyCut: UFix64) {
      HoodlumsMetadata.sturdyRoyaltyCut = sturdyRoyaltyCut;
    }

    access(MetadataAdmin) fun setArtistRoyaltyCut(artistRoyaltyCut: UFix64) {
      HoodlumsMetadata.artistRoyaltyCut = artistRoyaltyCut;
    }
  }

  access(all) view fun getMetadata(tokenID: UInt64): {String: String}? {
    return HoodlumsMetadata.metadata[tokenID]
  }

  init() {
    self.AdminStoragePath = /storage/HoodlumsMetadataAdmin

    self.metadata = {}

    self.sturdyRoyaltyAddress = 0xbb4ed9133bdab28a
    self.artistRoyaltyAddress = 0x985bafb3357d729b
    self.sturdyRoyaltyCut = 0.05
    self.artistRoyaltyCut = 0.05

    let admin <- create Admin()
    self.account.storage.save(<-admin, to: self.AdminStoragePath)

    emit ContractInitialized()
  }
}