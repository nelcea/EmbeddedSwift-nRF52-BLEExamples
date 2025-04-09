@main
struct Main {
  static func main() {
    BLE.setAddress("FF:EE:DD:CC:BB:AA")
    BLE.enable()

    let advertisement = BLEAdvertisement(parameters: bt_le_adv_param.bt_le_adv_conn3(),
          advertisementData: [
            BTDataTypes.flags(BLEFlags.generalDiscoverable | BLEFlags.noBREDR),
            BTDataTypes.nameComplete(CONFIG_BT_DEVICE_NAME)
          ], scanResponseData: [
            BTDataTypes.uuid(BTUUID(0x00001523, 0x1212, 0xefde, 0x1523, 0x785feabcd123))
          ])
    advertisement.start()

    while true {
      k_msleep(5000)
    }
  }
}

// MARK: BLE stack

/// Represents the BLE stack
struct BLE {
  static func setAddress(_ address: String) {
    var addr = bt_addr_le_t()
    var err = bt_addr_le_from_str(address, "random", &addr)
    if (err != 0) {
        fatalError("Invalid BT address (err \(err))")
    }

    err = bt_id_create(&addr, nil)
    if (err < 0) {
        fatalError("Creating new ID failed (err \(err))")
    }
  }

  static func enable() {
    let err = bt_enable(nil)
    if (err != 0) {
	    fatalError("Bluetooth init failed (err \(err)")  
    }
    print("Bluetooth initialized")
  }
}

// MARK: Advertisement data

/// Encapsulate Advertisement and ScanResponse data in a non Copyable struct
/// makes it easier to manage memory for this data
struct AdvertisementAndScanResponse: ~Copyable {
  private var advertisementData: [BTData]
  private var scanResponseData: [BTData]
  private(set) var ad: UnsafeMutablePointer<bt_data>
  private(set) var sd: UnsafeMutablePointer<bt_data>

  var adCount: Int {
    advertisementData.count
  }

  var sdCount: Int {
    scanResponseData.count
  }

  init(advertisementData: [BTData], scanResponseData: [BTData]) {
    self.advertisementData = advertisementData
    self.scanResponseData = scanResponseData
    self.ad = Self.btDataBytes(btData: advertisementData)
    self.sd = Self.btDataBytes(btData: scanResponseData)
  }

  private static func btDataBytes(btData: [BTData]) -> UnsafeMutablePointer<bt_data> {
    let ret = UnsafeMutablePointer<bt_data>.allocate(capacity: btData.count)
    for (index, value) in btData.enumerated() {
      var value = value
      ret[index].type = value.type
      ret[index].data_len = UInt8(value.bytes.count)
      let data = UnsafeMutablePointer<UInt8>.allocate(capacity: value.bytes.count)
      data.initialize(from: &value.bytes, count: value.bytes.count)
      ret[index].data = UnsafePointer(data)
    }
    return ret
  }

  func release(data: UnsafeMutablePointer<bt_data>, for btData: [BTData]) {
    for (index, _)  in btData.enumerated() {
      data[index].data.deallocate()
    }
    data.deallocate()
  }

  deinit {
    release(data: self.ad, for: self.advertisementData)
    release(data: self.sd, for: self.scanResponseData)
  }

}

struct BLEAdvertisement: ~Copyable {
  private var parameters: UnsafeMutablePointer<bt_le_adv_param>
  private let adsd: AdvertisementAndScanResponse

  init(parameters: bt_le_adv_param, advertisementData: [BTDataTypes], scanResponseData: [BTDataTypes]) {
    var params = parameters
    self.parameters = UnsafeMutablePointer<bt_le_adv_param>.allocate(capacity: 1)
    self.parameters.initialize(from: &params, count: 1)

    self.adsd = AdvertisementAndScanResponse(advertisementData: advertisementData.map { $0.btData },
                                              scanResponseData: scanResponseData.map { $0.btData })
  }

  func start() {
    bt_le_adv_start(self.parameters, adsd.ad, adsd.adCount, adsd.sd, adsd.sdCount)
  }

  deinit {
    self.parameters.deallocate()
  }
}

extension bt_le_adv_param {
  init(options: UInt32, minInterval: UInt32, maxInterval: UInt32) {
    self.init(id: UInt8(BT_ID_DEFAULT),
              sid: 0,
              secondary_max_skip: 0,
              options: options,
              interval_min: minInterval,
              interval_max: maxInterval,
              peer: nil)
  }
}

extension bt_le_adv_param {
  static func bt_le_adv_conn3() -> bt_le_adv_param {
    return bt_le_adv_param(options: UInt32(BT_LE_ADV_OPT_CONNECTABLE | BT_LE_ADV_OPT_USE_IDENTITY), minInterval: 800, maxInterval: 801)
  }
}

enum BLEFlags {
  static let generalDiscoverable = UInt8(BT_LE_AD_GENERAL)
  static let noBREDR = UInt8(BT_LE_AD_NO_BREDR)
}

// MARK: Data types

enum BTDataTypes {
  case flags(UInt8)
  case nameComplete(String)
  case uuid(BTUUID)

  var btData: BTData {
    switch self {
      case .flags(let flag):
        return BTData(type: UInt8(BT_DATA_FLAGS), bytes: [flag])
      case .nameComplete(let name):
        return BTData(type: UInt8(BT_DATA_NAME_COMPLETE), bytes: Array(name.utf8))
      case.uuid(let uuid):
        return BTData(type: UInt8(BT_DATA_UUID128_ALL), bytes: uuid.bytes)
    }
  }
}

struct BTData {
  let type: UInt8
  var bytes: [UInt8]
}

struct BTUUID {
  var uuid: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

  init(_ w32: UInt32, _ w1: UInt16, _ w2: UInt16, _ w3: UInt16, _ w48: UInt64) {
    // In all those method, index is 0 based, starting with MSB
    func byte(_ index: UInt8, in v: UInt16) -> UInt8 {
      return UInt8((v >> (8 * (1 - index))) & 0xFF)
    }
    func byte(_ index: UInt8, in v: UInt32) -> UInt8 {
      return UInt8((v >> (8 * (3 - index))) & 0xFF)
    }

    func byte(_ index: UInt8, in v: UInt64) -> UInt8 {
      return UInt8((v >> (8 * (7 - index))) & 0xFF)
    }

    // BLE specs indicates that "Multi-octet fields within the GATT profile shall be sent least significant octet
    // first (little-endian) with the exception of the Characteristic Value field.", hence the reverse ordering here
    uuid = (byte(7, in: w48), byte(6, in: w48), byte(5, in: w48), byte(4, in: w48), byte(3, in: w48), byte(2, in: w48),
            byte(1, in: w3), byte(0, in: w3),
            byte(1, in: w2), byte(0, in: w2),
            byte(1, in: w1), byte(0, in: w1),
            byte(3, in: w32), byte(2, in: w32), byte(1, in: w32), byte(0, in: w32)
            )
  }

  var bytes: [UInt8] {
    return [uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7,
            uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15]
  }
}