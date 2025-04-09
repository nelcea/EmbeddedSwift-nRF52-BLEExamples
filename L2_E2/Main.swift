@main
struct Main {
  static func main() {
    BLE.enable()

    var manufacturerData = ManufacturerData(companyCode: 0x59, numberOfPresses: 0)

    var advertisement = BLEAdvertisement(parameters: bt_le_adv_param(options: UInt32(BT_LE_ADV_OPT_NONE), minInterval: 800, maxInterval: 801),
          advertisementData: [
            BTDataTypes.flags(BLEFlags.generalDiscoverable | BLEFlags.noBREDR),
            BTDataTypes.nameComplete(CONFIG_BT_DEVICE_NAME),
            BTDataTypes.manufacturerData(manufacturerData.bytes)
          ], scanResponseData: [
            BTDataTypes.uri(BTURI(uri: "https://www.ericbariaux.com"))
          ])
    advertisement.start()


    while true {
      k_msleep(5000)
      manufacturerData.numberOfPresses += 1
      advertisement.update(advertisementData: [
            BTDataTypes.flags(BLEFlags.generalDiscoverable | BLEFlags.noBREDR),
            BTDataTypes.nameComplete(CONFIG_BT_DEVICE_NAME),
            BTDataTypes.manufacturerData(manufacturerData.bytes)
          ], scanResponseData: [
            BTDataTypes.uri(BTURI(uri: "https://www.ericbariaux.com"))
          ])
    }
  }
}

// MARK: BLE stack

/// Represents the BLE stack
struct BLE {
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
  private var adsd: AdvertisementAndScanResponse

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

  mutating func update(advertisementData: [BTDataTypes], scanResponseData: [BTDataTypes]) {
    self.adsd = AdvertisementAndScanResponse(advertisementData: advertisementData.map { $0.btData },
                                          scanResponseData: scanResponseData.map { $0.btData })

    bt_le_adv_update_data(adsd.ad, adsd.adCount, adsd.sd, adsd.sdCount)
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
  /// Equivalent of the BT_LE_ADV_NCONN C macro, defining a non-connectable advertising with private address.
  static func bt_le_adv_nconn() -> bt_le_adv_param {
    return bt_le_adv_param(options: 0, minInterval: UInt32(BT_GAP_ADV_FAST_INT_MIN_2), maxInterval: UInt32(BT_GAP_ADV_FAST_INT_MAX_2))
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
  case uri(BTURI)
  case manufacturerData([UInt8])

  var btData: BTData {
    switch self {
      case .flags(let flag):
        return BTData(type: UInt8(BT_DATA_FLAGS), bytes: [flag])
      case .nameComplete(let name):
        return BTData(type: UInt8(BT_DATA_NAME_COMPLETE), bytes: Array(name.utf8))
      case .uri(let uri):
        return BTData(type: UInt8(BT_DATA_URI), bytes: uri.bytes)
      case .manufacturerData(let bytes):
        return BTData(type: UInt8(BT_DATA_MANUFACTURER_DATA), bytes: bytes)
    }
  }
}

struct BTData {
  let type: UInt8
  var bytes: [UInt8]
}

struct ManufacturerData {
  let companyCode: UInt16
  var numberOfPresses: UInt16

  var bytes: [UInt8] {
    var me = self
    return withUnsafeBytes(of: &me) { Array($0) }
  }
}

// https://www.bluetooth.com/wp-content/uploads/Files/Specification/HTML/CSS_v11/out/en/supplement-to-the-bluetooth-core-specification/data-types-specification.html#UUID-64bd7c4c-daf3-7a73-143a-b3dba8faac95
struct BTURI {
  var uri: String

  var bytes: [UInt8] {
    if let colonIndex = uri.firstIndex(of: ":") {
      let scheme = String(uri[...colonIndex])
      if let schemeInt = Self.schemeMapping[scheme] {
        let slashIndex = uri.index(after: colonIndex)
        return [schemeInt] + Array(uri[slashIndex...].utf8)
      }
    }
    // Neither permanent of provisional scheme, include full URI string
    return [UInt8(1)] + Array(uri.utf8)
  }

  // See [bluetooth-SIG / public / assigned_numbers / core / uri_schemes.yaml — Bitbucket](https://bitbucket.org/bluetooth-SIG/public/src/main/assigned_numbers/core/uri_schemes.yaml)
  static private let schemeMapping: [String: UInt8] = [
//    "empty scheme name": 0x01, // We handle this case specifically in the above method, as the scheme is then part of the packet
    "aaa:": 0x02,
    "aaas:": 0x03,
    "about:": 0x04,
    "acap:": 0x05,
    "acct:": 0x06,
    "cap:": 0x07,
    "cid:": 0x08,
    "coap:": 0x09,
    "coaps:": 0x0a,
    "crid:": 0x0b,
    "data:": 0x0c,
    "dav:": 0x0d,
    "dict:": 0x0e,
    "dns:": 0x0f,
    "file:": 0x10,
    "ftp:": 0x11,
    "geo:": 0x12,
    "go:": 0x13,
    "gopher:": 0x14,
    "h323:": 0x15,
    "http:": 0x16,
    "https:": 0x17,
    "iax:": 0x18,
    "icap:": 0x19,
    "im:": 0x1a,
    "imap:": 0x1b,
    "info:": 0x1c,
    "ipp:": 0x1d,
    "ipps:": 0x1e,
    "iris:": 0x1f,
    "iris.beep:": 0x20,
    "iris.xpc:": 0x21,
    "iris.xpcs:": 0x22,
    "iris.lwz:": 0x23,
    "jabber:": 0x24,
    "ldap:": 0x25,
    "mailto:": 0x26,
    "mid:": 0x27,
    "msrp:": 0x28,
    "msrps:": 0x29,
    "mtqp:": 0x2a,
    "mupdate:": 0x2b,
    "news:": 0x2c,
    "nfs:": 0x2d,
    "ni:": 0x2e,
    "nih:": 0x2f,
    "nntp:": 0x30,
    "opaquelocktoken:": 0x31,
    "pop:": 0x32,
    "pres:": 0x33,
    "reload:": 0x34,
    "rtsp:": 0x35,
    "rtsps:": 0x36,
    "rtspu:": 0x37,
    "service:": 0x38,
    "session:": 0x39,
    "shttp:": 0x3a,
    "sieve:": 0x3b,
    "sip:": 0x3c,
    "sips:": 0x3d,
    "sms:": 0x3e,
    "snmp:": 0x3f,
    "soap.beep:": 0x40,
    "soap.beeps:": 0x41,
    "stun:": 0x42,
    "stuns:": 0x43,
    "tag:": 0x44,
    "tel:": 0x45,
    "telnet:": 0x46,
    "tftp:": 0x47,
    "thismessage:": 0x48,
    "tn3270:": 0x49,
    "tip:": 0x4a,
    "turn:": 0x4b,
    "turns:": 0x4c,
    "tv:": 0x4d,
    "urn:": 0x4e,
    "vemmi:": 0x4f,
    "ws:": 0x50,
    "wss:": 0x51,
    "xcon:": 0x52,
    "xcon-userid:": 0x53,
    "xmlrpc.beep:": 0x54,
    "xmlrpc.beeps:": 0x55,
    "xmpp:": 0x56,
    "z39.50r:": 0x57,
    "z39.50s:": 0x58,
    "acr:": 0x59,
    "adiumxtra:": 0x5a,
    "afp:": 0x5b,
    "afs:": 0x5c,
    "aim:": 0x5d,
    "apt:": 0x5e,
    "attachment:": 0x5f,
    "aw:": 0x60,
    "barion:": 0x61,
    "beshare:": 0x62,
    "bitcoin:": 0x63,
    "bolo:": 0x64,
    "callto:": 0x65,
    "chrome:": 0x66,
    "chrome-extension:": 0x67,
    "com-eventbrite-attendee:": 0x68,
    "content:": 0x69,
    "cvs:": 0x6a,
    "dlna-playsingle:": 0x6b,
    "dlna-playcontainer:": 0x6c,
    "dtn:": 0x6d,
    "dvb:": 0x6e,
    "ed2k:": 0x6f,
    "facetime:": 0x70,
    "feed:": 0x71,
    "feedready:": 0x72,
    "finger:": 0x73,
    "fish:": 0x74,
    "gg:": 0x75,
    "git:": 0x76,
    "gizmoproject:": 0x77,
    "gtalk:": 0x78,
    "ham:": 0x79,
    "hcp:": 0x7a,
    "icon:": 0x7b,
    "ipn:": 0x7c,
    "irc:": 0x7d,
    "irc6:": 0x7e,
    "ircs:": 0x7f,
    "itms:": 0x80,
    "jar:": 0x81,
    "jms:": 0x82,
    "keyparc:": 0x83,
    "lastfm:": 0x84,
    "ldaps:": 0x85,
    "magnet:": 0x86,
    "maps:": 0x87,
    "market:": 0x88,
    "message:": 0x89,
    "mms:": 0x8a,
    "ms-help:": 0x8b,
    "ms-settings-power:": 0x8c,
    "msnim:": 0x8d,
    "mumble:": 0x8e,
    "mvn:": 0x8f,
    "notes:": 0x90,
    "oid:": 0x91,
    "palm:": 0x92,
    "paparazzi:": 0x93,
    "pkcs11:": 0x94,
    "platform:": 0x95,
    "proxy:": 0x96,
    "psyc:": 0x97,
    "query:": 0x98,
    "res:": 0x99,
    "resource:": 0x9a,
    "rmi:": 0x9b,
    "rsync:": 0x9c,
    "rtmfp:": 0x9d,
    "rtmp:": 0x9e,
    "secondlife:": 0x9f,
    "sftp:": 0xa0,
    "sgn:": 0xa1,
    "skype:": 0xa2,
    "smb:": 0xa3,
    "smtp:": 0xa4,
    "soldat:": 0xa5,
    "spotify:": 0xa6,
    "ssh:": 0xa7,
    "steam:": 0xa8,
    "submit:": 0xa9,
    "svn:": 0xaa,
    "teamspeak:": 0xab,
    "teliaeid:": 0xac,
    "things:": 0xad,
    "udp:": 0xae,
    "unreal:": 0xaf,
    "ut2004:": 0xb0,
    "ventrilo:": 0xb1,
    "view-source:": 0xb2,
    "webcal:": 0xb3,
    "wtai:": 0xb4,
    "wyciwyg:": 0xb5,
    "xfire:": 0xb6,
    "xri:": 0xb7,
    "ymsgr:": 0xb8,
    "example:": 0xb9,
    "ms-settings-cloudstorage:": 0xba
  ]
}