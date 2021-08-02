const fs = require('fs');
const crypto = require('crypto');

let streams = {}
let lastKey = 1;

function Ok(v) {
    return {
        result: 'Ok',
        data: v
    }
}

function Err(e) {
    return {
        result: 'Err',
        data: e
    }
}

function encodeError(err) {
    return Err({
        code: err.code || 'NONE',
        msg: err.message,
    });
}

module.exports = {
    readFile: function(name) {
        try {
            const content = fs.readFileSync(name).toString();
            return Ok(content);
        } catch (err) {
            return encodeError(err);
        }
    },
    writeFile: function(name, content, options) {
        try {
            fs.writeFileSync(name, content, options);
            return Ok(null);
        } catch (err) {
            return encodeError(err);
        }
    },
    fopen: function(filename, flags) {
        try {
            return fs.openSync(filename, flags);
        } catch (e) {
            return e.toString();
        }
    },
    fstat: function(filename) {
        try {
            return fs.statSync(filename);
        } catch (e) {
            return e.toString();
        }
    },
    readdir: function(dirname) {
        try {
            var r = fs.readdirSync(dirname, { withFileTypes: true })
                .map(dirent => ({
                    name: dirent.name,
                    isDir: dirent.isDirectory(),
                    isFile: dirent.isFile(),
                    isSocket: dirent.isSocket(),
                    isFifo: dirent.isFIFO(),
                    isSymlink: dirent.isSymbolicLink(),
                    isBlockDevice: dirent.isBlockDevice(),
                    isCharacterDevice: dirent.isCharacterDevice(),
                }));
            return r;
        } catch (e) {
            return e.toString();
        }
    },
    randomSeed: function() {
        return crypto.randomBytes(4).readInt32LE();
    },
    print: function(str) {
        fs.writeFileSync(1, str);
    },
    panic: function(msg) {
        console.error(msg);
        process.exit(255);
    },
    exit: function(status) {
        process.exit(status);
    },
    // Streams
    openReadStream: function(filename, bufferSize) {
        var key = 'read-' + ++lastKey;

        try {
            var file = fs.openSync(filename);
        } catch (err) {
            return encodeError(err);
        }

        streams[key] = it => readGenerator(file, bufferSize);

        return Ok({ id: key });
    },
    openWriteStream: function(filename, options) {
        var key = 'write-' + ++lastKey;

        try {
            var file = fs.openSync(filename, options.flag, options.mode);
        } catch (err) {
            return encodeError(err);
        }

        streams[key] = it => writeGenerator(file, it);

        return Ok({ id: key });
    },
    readStream: function(pipes) {
        const key = piplineKey(pipes);

        let iterator = streams[key];

        if (!iterator) {
            iterator = createPipeline(pipes);
            streams[key] = iterator;
        }

        let val = null;

        try {
            val = iterator.next().value;
        } catch (err) {
            return encodeError(err);
        }

        if (val == undefined) {
            return Ok(null);
        } else if (val instanceof Buffer) {
            return Ok([...val.values()]);
        }

        return Ok(val);
    },
    writeStream: function(pipes, data) {
        if (Array.isArray(data)) {
            data = Buffer.from(data);
        }
        let iterator = createPipeline(pipes, valueToIterator(data));
        let bytesWritten = iterator.next().value

        return Ok(bytesWritten);
    },
}

function piplineKey(pipes) {
    return 'pipe:' + pipes.map(p => p.id).join(':');
}

function createPipeline(pipes, iterator) {
    let pipe = null;

    while (pipe = pipes.shift()) {
        switch (pipe.id) {
            case 'utf8Decode':
                iterator = utf8Decode(iterator);
                break;

            case 'utf8Encode':
                iterator = utf8Encode(iterator);
                break;

            case 'line':
                iterator = splitLine(iterator);
                break;

            default:
                iterator = streams[pipe.id](iterator);
        }
    }

    return iterator;
}

function * splitLine(iterator) {
    let val = iterator.next().value;
    let buf = [];

    while (val) {
        let lines = val.split("\n");

        if (lines.length == 1) {
            buf.push(lines[0]);
        } else {
            let last = lines.pop();
            let prev = buf.join('');
            let first = lines.shift();
            buf = [ last ];

            yield prev + first;
            for (let line of lines) {
                yield line;
            }
        }

        val = iterator.next().value;
    }

    if (buf.length > 0 ) {
        yield buf.join('');
    }
}

function * utf8Encode(iterator) {
    let data = iterator.next().value;

    while (data) {
        if (data instanceof Buffer) {
            yield data;
        } else {
            yield Buffer.from(data);
        }

        data = iterator.next().value;
    }
}

function * utf8Decode(it) {
    let buffer = it.next(0).value;
    let partialMbBuffer = null;

    while (buffer) {
        const mbOffsetFromEnd = utf8_mbOffsetFromEnd(buffer);

        if (!mbOffsetFromEnd) {
            // No broken mb characters at the end of the buffer.
            yield buffer.toString('utf8');
        } else {
            // We have a partial multibyte char at the end.of the buffer.
            // yield everythin but the partial multibyte char.
            yield buffer.toString('utf8', 0, buffer.length - mbOffsetFromEnd);


            // Copy the partial multibyte char to the beginning of the buffer.
            buffer.copy(buffer, 0, buffer.length - mbOffsetFromEnd, buffer.length);
        }

        // Load more data into the buffer with offset.
        buffer = it.next(mbOffsetFromEnd).value;
    }
}

function utf8_mbOffsetFromEnd(buf) {
    const lastIdx = buf.length - 1;
    let idx = 1;
    let mbWidth = utf8_getMbWidth(buf[lastIdx]);

    if (!mbWidth) {
        // last byte is not multibyte.
        return 0;
    }

    while (true) {
        if (mbWidth == 1) {
            // we got a tail byte of a multibyte char
            // continue to search for the start byte.
            mbWidth = utf8_getMbWidth(buf[lastIdx - idx]);
            idx++;
        } else {
            // we got the start byte of a multibyte char.
            if (idx == mbWidth) {
                return 0;
            }
            return idx;
        }
    }
}

function utf8_getMbWidth(b) {
    // 1xxx xxxx
    if (b & 0x80) {
        if ((b & 0xF0) === 0xF0) { // 1111 xxxx
            // start of 4 byte char
            return 4;
        } else if ((b & 0xE0) === 0xE0) { // 111x xxxx
            // start of 3 byte char
            return 3;
        } else if ((b & 0xC0) === 0xC0) { // 11xx xxxx
            // start of 2 byte char
            return 2;
        }
        // Tail of mb char.
        return 1;
    }

    // Not a multi byte char.
    return 0;
}

function * readGenerator(fd, bufferSize) {
    const buffer = Buffer.alloc(bufferSize);
    let offset = 0;
    let bytesRead = fs.readSync(fd, buffer, offset, buffer.length - offset, null);

    while (bytesRead) {
        if (bytesRead < buffer.length - offset) {
            offset = yield buffer.slice(0, bytesRead);
        } else {
            offset = yield buffer;
        }
        bytesRead = fs.readSync(fd, buffer, offset, buffer.length - offset, null);
    }
}

function * writeGenerator(fd, iterator) {
    let data = iterator.next().value;

    while (data) {
        yield fs.writeSync(fd, data);
        data = iterator.next().value;
    }
}

function * valueToIterator(data) {
    yield data;
}
