//
//  Web3+Structures.swift
//  Alamofire
//
//  Created by Alexander Vlasov on 26.12.2017.
//

import Foundation
import BigInt

public struct TransactionDetails {
    public var hash: String
    public var nonce: BigUInt
    public var blockHash: String?
    public var blockNumber: BigUInt?
    public var transactionIndex: BigUInt?
    public var from: EthereumAddress
    public var to: EthereumAddress
    public var value: BigUInt
    public var gasLimit: BigUInt
    public var gasPrice: BigUInt
    public var input: Data
    
    public init? (_ json: [String: AnyObject]) {
        guard let h = json["hash"] as? String else {return nil}
        guard let n = json["nonce"] as? String else {return nil}
        let bh = json["blockHash"] as? String
        let bn = json["blockNumber"] as? String
        let ti = json["transactionIndex"] as? String
        guard let f = json["from"] as? String else {return nil}
        guard let t = json["to"] as? String else {return nil}
        guard let v = json["value"] as? String else {return nil}
        guard let g = json["gas"] as? String else {return nil}
        guard let gp = json["gasPrice"] as? String else {return nil}
        guard let i = json["input"] as? String else {return nil}
        
        hash = h
        guard let nUnwrapped = BigUInt(n.stripHexPrefix(), radix: 16) else {return nil}
        nonce = nUnwrapped
        blockHash = bh
        if bn != nil {
            blockNumber = BigUInt(bn!.stripHexPrefix(), radix: 16)
        }
        if ti != nil {
            transactionIndex = BigUInt(ti!.stripHexPrefix(), radix: 16)
        }
        
        from = EthereumAddress(f)
        to = EthereumAddress(t)
        guard let vUnwrapped = BigUInt(v.stripHexPrefix(), radix: 16) else {return nil}
        guard let gUnwrapped = BigUInt(g.stripHexPrefix(), radix: 16) else {return nil}
        guard let gpUnwrapped = BigUInt(gp.stripHexPrefix(), radix: 16) else {return nil}
        value = vUnwrapped
        gasLimit = gUnwrapped
        gasPrice = gpUnwrapped
        input = Data(Array<UInt8>(hex: i.lowercased().stripHexPrefix()))
    }
}

public struct TransactionReceipt {
    public var transactionHash: String
    public var blockHash: String
    public var blockNumber: BigUInt
    public var transactionIndex: BigUInt
    public var contractAddress: EthereumAddress?
    public var cumulativeGasUsed: BigUInt
    public var gasUsed: BigUInt
    public var logs: [EventLog]
    public var status: TXStatus
    
    public enum TXStatus {
        case ok
        case failed
        case notYetProcessed
    }
    
    public init? (_ json: [String: AnyObject]) {
        guard let h = json["transactionHash"] as? String else {return nil}
        guard let bh = json["blockHash"] as? String else {return nil}
        guard let bn = json["blockNumber"] as? String else {return nil}
        guard let ti = json["transactionIndex"] as? String else {return nil}
        let ca = json["contractAddress"] as? String
        guard let cgu = json["cumulativeGasUsed"] as? String else {return nil}
        guard let gu = json["gasUsed"] as? String else {return nil}
        guard let ls = json["logs"] as? Array<[String:AnyObject]> else {return nil}
        let st = json["status"] as? String
        
        transactionHash = h
        blockHash = bh
        guard let bnUnwrapped = BigUInt(bn.stripHexPrefix(), radix: 16) else {return nil}
        blockNumber = bnUnwrapped
        guard let tiUnwrapped = BigUInt(ti.stripHexPrefix(), radix: 16) else {return nil}
        transactionIndex = tiUnwrapped
        if ca != nil {
            contractAddress = EthereumAddress(ca!.addHexPrefix())
        }
        guard let cguUnwrapped = BigUInt(cgu.stripHexPrefix(), radix: 16) else {return nil}
        cumulativeGasUsed = cguUnwrapped
        guard let guUnwrapped = BigUInt(gu.stripHexPrefix(), radix: 16) else {return nil}
        gasUsed = guUnwrapped
        var allLogs = [EventLog]()
        for l in ls {
            guard let log = EventLog(l) else {return nil}
            allLogs.append(log)
        }
        logs = allLogs
        if (st == nil) {
            status = TXStatus.notYetProcessed
        } else if st == "0x1" {
            status = TXStatus.ok
        } else {
            status = TXStatus.failed
        }
    }
}

public struct EventLog {
    public var address: EthereumAddress
    public var data: Data
    public var logIndex: BigUInt
    public var removed: Bool
    public var topics: [Data]
    
    public init? (_ json: [String: AnyObject]) {
        guard let ad = json["address"] as? String else {return nil}
        guard let d = json["data"] as? String else {return nil}
        guard let li = json["logIndex"] as? String else {return nil}
        guard let rm = json["removed"] as? Int else {return nil}
        guard let tpc = json["topics"] as? [String] else {return nil}
        address = EthereumAddress(ad)
        data = Data.fromHex(d)!
        guard let liUnwrapped = BigUInt(li.stripHexPrefix(), radix: 16) else {return nil}
        logIndex = liUnwrapped
        removed = rm == 1 ? true : false
        var tops = [Data]()
        for t in tpc {
            guard let topic = Data.fromHex(t) else {return nil}
            tops.append(topic)
        }
        topics = tops
    }
}

public enum TransactionInBlock:Decodable {
    case hash(Data)
    case transaction(EthereumTransaction)
    case null
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let string = try? value.decode(String.self) {
            guard let d = Data.fromHex(string) else {throw Web3Error.dataError}
            self = .hash(d)
        } else if let dict = try? value.decode([String:String].self) {
            guard let t = EthereumTransaction.fromJSON(dict) else {throw Web3Error.dataError}
            self = .transaction(t)
        } else {
            self = .null
        }
    }
    
    
    public init?(_ data: AnyObject) {
        if let string = data as? String {
            guard let d = Data.fromHex(string) else {return nil}
            self = .hash(d)
        } else if let dict = data as? [String:AnyObject] {
            guard let t = EthereumTransaction.fromJSON(dict) else {return nil}
            self = .transaction(t)
        } else {
            return nil
        }
    }
}

public struct Block:Decodable {
    public var number: BigUInt
    public var hash: Data
    public var parentHash: Data
    public var nonce: Data?
    public var sha3Uncles: Data
    public var logsBloom: EthereumBloomFilter?
    public var transactionsRoot: Data
    public var stateRoot: Data
    public var receiptsRoot: Data
    public var miner: EthereumAddress?
    public var difficulty: BigUInt
    public var totalDifficulty: BigUInt
    public var extraData: Data
    public var size: BigUInt
    public var gasLimit: BigUInt
    public var gasUsed: BigUInt
    public var timestamp: Date
    public var transactions: [TransactionInBlock]
    public var uncles: [Data]
    
    enum CodingKeys: String, CodingKey
    {
        case number
        case hash
        case parentHash
        case nonce
        case sha3Uncles
        case logsBloom
        case transactionsRoot
        case stateRoot
        case receiptsRoot
        case miner
        case difficulty
        case totalDifficulty
        case extraData
        case size
        case gasLimit
        case gasUsed
        case timestamp
        case transactions
        case uncles
    }
    
    public init(from decoder: Decoder) throws {
        func decodeHexToData(_ container:  KeyedDecodingContainer<Block.CodingKeys>, key: KeyedDecodingContainer<Block.CodingKeys>.Key, allowOptional:Bool = false) throws -> Data? {
            if (allowOptional) {
                let string = try? container.decode(String.self, forKey: key)
                if string != nil {
                    guard let data = Data.fromHex(string!) else {throw Web3Error.dataError}
                    return data
                }
                return nil
            } else {
                let string = try container.decode(String.self, forKey: key)
                guard let data = Data.fromHex(string) else {throw Web3Error.dataError}
                return data
            }
        }
        
        func decodeHexToBigUInt(_ container:  KeyedDecodingContainer<Block.CodingKeys>, key: KeyedDecodingContainer<Block.CodingKeys>.Key, allowOptional:Bool = false) throws -> BigUInt? {
            if (allowOptional) {
                let string = try? container.decode(String.self, forKey: key)
                if string != nil {
                    guard let number = BigUInt(string!.stripHexPrefix(), radix: 16) else {throw Web3Error.dataError}
                    return number
                }
                return nil
            } else {
                let string = try container.decode(String.self, forKey: key)
                guard let number = BigUInt(string.stripHexPrefix(), radix: 16) else {throw Web3Error.dataError}
                return number
            }
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let number = try decodeHexToBigUInt(container, key: .number) else {throw Web3Error.dataError}
        self.number = number
        
        guard let hash = try decodeHexToData(container, key: .hash) else {throw Web3Error.dataError}
        self.hash = hash
        
        guard let parentHash = try decodeHexToData(container, key: .parentHash) else {throw Web3Error.dataError}
        self.parentHash = parentHash
        
        let nonce = try decodeHexToData(container, key: .nonce, allowOptional: true)
        self.nonce = nonce
        
        guard let sha3Uncles = try decodeHexToData(container, key: .sha3Uncles) else {throw Web3Error.dataError}
        self.sha3Uncles = sha3Uncles
        
        let logsBloomData = try decodeHexToData(container, key: .logsBloom, allowOptional: true)
        var bloom:EthereumBloomFilter?
        if logsBloomData != nil {
            bloom = EthereumBloomFilter(logsBloomData!)
        }
        self.logsBloom = bloom
        
        guard let transactionsRoot = try decodeHexToData(container, key: .transactionsRoot) else {throw Web3Error.dataError}
        self.transactionsRoot = transactionsRoot
        
        guard let stateRoot = try decodeHexToData(container, key: .stateRoot) else {throw Web3Error.dataError}
        self.stateRoot = stateRoot
        
        guard let receiptsRoot = try decodeHexToData(container, key: .receiptsRoot) else {throw Web3Error.dataError}
        self.receiptsRoot = receiptsRoot
        
        let minerAddress = try? container.decode(String.self, forKey: .miner)
        var miner:EthereumAddress?
        if minerAddress != nil {
            miner = EthereumAddress(minerAddress!)
            guard miner!.isValid else {throw Web3Error.dataError}
        }
        self.miner = miner
        
        guard let difficulty = try decodeHexToBigUInt(container, key: .difficulty) else {throw Web3Error.dataError}
        self.difficulty = difficulty
        
        guard let totalDifficulty = try decodeHexToBigUInt(container, key: .totalDifficulty) else {throw Web3Error.dataError}
        self.totalDifficulty = totalDifficulty
        
        guard let extraData = try decodeHexToData(container, key: .extraData) else {throw Web3Error.dataError}
        self.extraData = extraData
        
        guard let size = try decodeHexToBigUInt(container, key: .size) else {throw Web3Error.dataError}
        self.size = size
        
        guard let gasLimit = try decodeHexToBigUInt(container, key: .gasLimit) else {throw Web3Error.dataError}
        self.gasLimit = gasLimit
        
        guard let gasUsed = try decodeHexToBigUInt(container, key: .gasUsed) else {throw Web3Error.dataError}
        self.gasUsed = gasUsed
        
        let timestampString = try container.decode(String.self, forKey: .timestamp).stripHexPrefix()
        guard let timestampInt = UInt64(timestampString, radix: 16) else {throw Web3Error.dataError}
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        self.timestamp = timestamp
        
        let transactions = try container.decode([TransactionInBlock].self, forKey: .transactions)
        self.transactions = transactions
        
        let unclesStrings = try container.decode([String].self, forKey: .uncles)
        var uncles = [Data]()
        for str in unclesStrings {
            guard let d = Data.fromHex(str) else {throw Web3Error.dataError}
            uncles.append(d)
        }
        self.uncles = uncles
    }
}
