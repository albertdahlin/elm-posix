const fs = require('fs');
const crypto = require('crypto');

module.exports = {
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
