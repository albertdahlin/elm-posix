const fs = require('fs');
const crypto = require('crypto');

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
    fwrite: function(fd, content) {
        fs.writeSync(fd, content);
    },
    fread: function(fd) {
        return fs.readFileSync(fd).toString();
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
    panic: function(msg) {
        console.error(msg);
        process.exit(255);
    },
    exit: function(status) {
        process.exit(status);
    }
}
