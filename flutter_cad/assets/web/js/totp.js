/**
 * 根据密钥动态生成 9位开图验证码
 */
class TOTPGenerator {
  static to_ = "I5JVIQSGTKT";
  static tempString_ = "QKSK5AV";

  // 获取当前 TOTP 动态验证码
  static getTOTP(secretKey = this.to_ + this.tempString_) {
    // 取前 11 位和后 7 位
    const SecretKeybf = secretKey.substring(0, 11);
    const SecretKeybt = secretKey.substring(11, 18);

    // 替换 SecretKeybf 中的 "QS" 为 SecretKeybt
    secretKey = SecretKeybf.replace("QS", SecretKeybt);

    let code = "";
    try {
      code = this.calcTotp(
        this.decodeBase32(secretKey),
        0,
        30,
        Math.floor(Date.now() / 1000),
        9
      );
    } catch (e) {
      console.error("getTOTP error ", e);
    }
    return code;
  }

  // TOTP 核心函数
  static calcTotp(
    secretKey,
    epoch = 0,
    timeStep = 30,
    timestamp = Date.now(),
    codeLen = 6,
    hashFunc = this.calcSha1Hash,
    blockSize = 64
  ) {
    const timeCounter = Math.floor((timestamp - epoch) / timeStep);

    // 时间计数器转 8 字节（大端）
    const counter = [];
    for (let i = 0, tc = timeCounter; i < 8; i++, tc = Math.floor(tc / 256)) {
      counter.push(tc & 0xff);
    }
    counter.reverse();

    return this.calcHotp(secretKey, counter, codeLen, hashFunc, blockSize);
  }

  // Base32 解码
  static decodeBase32(str) {
    const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    const result = [];
    let bits = 0;
    let bitsLen = 0;

    for (const c of str) {
      if (c === " ") continue;
      const i = ALPHABET.indexOf(c.toUpperCase());
      if (i === -1) throw new RangeError("Invalid Base32 string");

      bits = (bits << 5) | i;
      bitsLen += 5;

      if (bitsLen >= 8) {
        bitsLen -= 8;
        result.push(bits >>> bitsLen);
        bits &= (1 << bitsLen) - 1;
      }
    }
    return result;
  }

  // 简化版 SHA-1
  static calcSha1Hash(message) {
    const bitLenBytes = [];
    let bitLen = message.length * 8;
    for (let i = 0; i < 8; i++, bitLen >>>= 8) {
      bitLenBytes.push(bitLen & 0xff);
    }
    bitLenBytes.reverse();

    const msg = message.slice();
    msg.push(0x80);
    while ((msg.length + 8) % 64 !== 0) msg.push(0x00);
    msg.push(...bitLenBytes);

    let state = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0];

    for (let i = 0; i < msg.length; i += 64) {
      const schedule = [];

      for (let j = 0; j < 64; j++) {
        if (j % 4 === 0) schedule.push(0);
        schedule[Math.floor(j / 4)] |= msg[i + j] << ((3 - (j % 4)) * 8);
      }

      for (let j = schedule.length; j < 80; j++) {
        const t =
          schedule[j - 3] ^
          schedule[j - 8] ^
          schedule[j - 14] ^
          schedule[j - 16];
        schedule.push((t << 1) | (t >>> 31));
      }

      let [a, b, c, d, e] = state;

      schedule.forEach((sch, j) => {
        let f, rc;
        switch (Math.floor(j / 20)) {
          case 0:
            f = (b & c) | (~b & d);
            rc = 0x5a827999;
            break;
          case 1:
            f = b ^ c ^ d;
            rc = 0x6ed9eba1;
            break;
          case 2:
            f = (b & c) ^ (b & d) ^ (c & d);
            rc = 0x8f1bbcdc;
            break;
          default:
            f = b ^ c ^ d;
            rc = 0xca62c1d6;
        }

        const temp = (((a << 5) | (a >>> 27)) + f + e + sch + rc) >>> 0;
        e = d;
        d = c;
        c = (b << 30) | (b >>> 2);
        b = a;
        a = temp;
      });

      state[0] = (state[0] + a) >>> 0;
      state[1] = (state[1] + b) >>> 0;
      state[2] = (state[2] + c) >>> 0;
      state[3] = (state[3] + d) >>> 0;
      state[4] = (state[4] + e) >>> 0;
    }

    const result = [];
    for (const val of state) {
      for (let i = 3; i >= 0; i--) {
        result.push((val >>> (i * 8)) & 0xff);
      }
    }
    return result;
  }

  // HOTP
  static calcHotp(
    secretKey,
    counter,
    codeLen = 6,
    hashFunc = this.calcSha1Hash,
    blockSize = 64
  ) {
    if (!(codeLen >= 1 && codeLen <= 9)) {
      throw new RangeError("Invalid number of digits");
    }

    const hash = this.calcHmac(secretKey, counter, hashFunc, blockSize);
    const offset = hash[hash.length - 1] % 16;

    let val = 0;
    for (let i = 0; i < 4; i++) {
      val |= hash[offset + i] << ((3 - i) * 8);
    }

    val &= 0x7fffffff;

    let tenPow = 1;
    for (let i = 0; i < codeLen; i++) tenPow *= 10;
    val %= tenPow;

    let s = val.toString();
    while (s.length < codeLen) s = "0" + s;
    return s;
  }

  // HMAC-SHA1
  static calcHmac(key, message, hashFunc, blockSize) {
    if (key.length > blockSize) key = hashFunc(key);

    const newKey = key.slice();
    while (newKey.length < blockSize) newKey.push(0x00);

    const inner = newKey.map((b) => b ^ 0x36).concat(message);
    const innerHash = hashFunc(inner);

    const outer = newKey.map((b) => b ^ 0x5c).concat(innerHash);
    return hashFunc(outer);
  }
}

/* 使用示例 */
// console.log(TOTPGenerator.getTOTP())
