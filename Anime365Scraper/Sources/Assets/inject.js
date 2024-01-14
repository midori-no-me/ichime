var open = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function() {
    this.addEventListener("load", function() {
        if (this.responseURL.includes('users/profile')) {
                webkit.messageHandlers.handler.postMessage({ success: true });
        }
    });
    open.apply(this, arguments);
};
/**
 * Parse PHP serialized data into JavaScript objects.
 *
 * @param {String} phpStr - PHP serialized string to parse
 * @return {mixed} - Parsed result
 */
function phpDeserialize(phpStr) {
    let idx = 0;
    let refStack = [];
    let ridx = 0;
    function readLength() {
        const delimiter = phpStr.indexOf(":", idx);
        const value = phpStr.substring(idx, delimiter);
        idx = delimiter + 2;
        return parseInt(value, 10);
    }
    function readInt() {
        const delimiter = phpStr.indexOf(";", idx);
        const value = phpStr.substring(idx, delimiter);
        idx = delimiter + 1;
        return parseInt(value, 10);
    }
    function parseAsInt() {
        const value = readInt();
        refStack[ridx++] = value;
        return value;
    }
    function parseAsFloat() {
        const delimiter = phpStr.indexOf(";", idx);
        const value = parseFloat(phpStr.substring(idx, delimiter));
        idx = delimiter + 1;
        refStack[ridx++] = value;
        return value;
    }
    function parseAsBoolean() {
        const delimiter = phpStr.indexOf(";", idx);
        const value = phpStr.substring(idx, delimiter) === "1" ? true : false;
        idx = delimiter + 1;
        refStack[ridx++] = value;
        return value;
    }
    function readString(expected = '') {
        const length = readLength();
        let utfLen = 0;
        let bytes = 0;
        let char;
        let value;
        while (bytes < length) {
            char = phpStr.charCodeAt(idx + utfLen++);
            if (char <= 0x007f) {
                bytes++;
            }
            else if (char > 0x07ff) {
                bytes += 3;
            }
            else {
                bytes += 2;
            }
        }
        if (phpStr.charAt(idx + utfLen) !== expected) {
            utfLen += phpStr.indexOf('"', idx + utfLen) - idx - utfLen;
        }
        value = phpStr.substring(idx, idx + utfLen);
        idx += utfLen + 2;
        return value;
    }
    function parseAsString() {
        const value = readString();
        refStack[ridx++] = value;
        return value;
    }
    function readType() {
        const type = phpStr.charAt(idx);
        idx += 2;
        return type;
    }
    function readKey() {
        const type = readType();
        switch (type) {
            case "i":
                return readInt();
            case "s":
                return readString();
            default:
                throw new Error(`Unknown key type '${type}' at position ${idx - 2}`);
        }
    }
    function parseAsArray() {
        const length = readLength();
        const resultArray = [];
        const resultHash = {};
        let keep = resultArray;
        const lref = ridx++;
        let key;
        let val;
        let i;
        let j;
        let arrayLength;
        refStack[lref] = keep;
        try {
            for (i = 0; i < length; i++) {
                key = readKey();
                val = parseNext();
                if (keep === resultArray && key + "" === i + "") {
                    resultArray.push(val);
                }
                else {
                    if (keep !== resultHash) {
                        for (j = 0, arrayLength = resultArray.length; j < arrayLength; j++) {
                            resultHash[j] = resultArray[j];
                        }
                        keep = resultHash;
                        refStack[lref] = keep;
                    }
                    resultHash[key] = val;
                }
            }
        }
        catch (e) {
            e.state = keep;
            throw e;
        }
        idx++;
        return keep;
    }
    function parseAsNull() {
        const value = null;
        refStack[ridx++] = value;
        return value;
    }
    function parseNext() {
        const type = readType();
        switch (type) {
            case "i":
                return parseAsInt();
            case "d":
                return parseAsFloat();
            case "b":
                return parseAsBoolean();
            case "s":
                return parseAsString();
            case "a":
                return parseAsArray();
            case "N":
                return parseAsNull();
            default:
                throw new Error(`Unknown type '${type}' at position ${idx - 2}`);
        }
    }
    return parseNext();
}
