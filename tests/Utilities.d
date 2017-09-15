import utils;

unittest
{
    /**
     * bswap
     */
    assert(bswap16(0xFFAA) == 0xAAFF);
    assert(bswap16(0x6600) == 0x66);
    assert(bswap16(0x66) == 0x6600);

    assert(bswap32(0xFFBBCCAA) == 0xAACCBBFF);
    assert(bswap32(0x12340000) == 0x3412);
    assert(bswap32(0x1234) == 0x34120000);

    assert(bswap64(0xAABBCCDD_00000000) == 0xDDCCBBAA);
    assert(bswap64(0xAABBCCDD) == 0xDDCCBBAA_00000000);
    assert(bswap64(0xAABBCCDD_EEFF1122) == 0x2211FFEE_DDCCBBAA);
}