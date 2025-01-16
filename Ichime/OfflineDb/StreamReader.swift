import CoreData
import Foundation

class StreamReader {
  let encoding: String.Encoding
  let chunkSize: Int
  var fileHandle: FileHandle!
  let delimData: Data
  var buffer: Data
  var atEof: Bool

  init?(
    path: String,
    delimiter: String = "\n",
    encoding: String.Encoding = .utf8,
    chunkSize: Int = 4096
  ) {
    guard let fileHandle = FileHandle(forReadingAtPath: path),
      let delimData = delimiter.data(using: encoding)
    else {
      return nil
    }
    self.encoding = encoding
    self.chunkSize = chunkSize
    self.fileHandle = fileHandle
    self.delimData = delimData
    self.buffer = Data(capacity: chunkSize)
    self.atEof = false
  }

  deinit {
    self.close()
  }

  /// Return next line, or nil on EOF.
  func nextLine() -> String? {
    precondition(self.fileHandle != nil, "Attempt to read from closed file")

    // Read data chunks from file until a line delimiter is found:
    while !self.atEof {
      if let range = buffer.range(of: delimData) {
        // Convert complete line (excluding the delimiter) to a string:
        let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: self.encoding)
        // Remove line (and the delimiter) from the buffer:
        self.buffer.removeSubrange(0..<range.upperBound)
        return line
      }
      let tmpData = self.fileHandle.readData(ofLength: self.chunkSize)
      if tmpData.count > 0 {
        self.buffer.append(tmpData)
      }
      else {
        // EOF or read error.
        self.atEof = true
        if self.buffer.count > 0 {
          // Buffer contains last line in file (not terminated by delimiter).
          let line = String(data: buffer as Data, encoding: encoding)
          self.buffer.count = 0
          return line
        }
      }
    }
    return nil
  }

  /// Start reading from the beginning of file.
  func rewind() -> Void {
    self.fileHandle.seek(toFileOffset: 0)
    self.buffer.count = 0
    self.atEof = false
  }

  /// Close the underlying file. No reading must be done after calling this method.
  func close() -> Void {
    self.fileHandle?.closeFile()
    self.fileHandle = nil
  }
}

extension StreamReader: Sequence {
  func makeIterator() -> AnyIterator<String> {
    AnyIterator {
      self.nextLine()
    }
  }
}
