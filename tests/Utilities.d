import utils;

unittest
{
    ushort s = 0xFFAA;
    assert(invert(s) == 0xAAFF);
    s = 0x6600;
    assert(invert(s) == 0x66);
    s = 0x66;
    assert(invert(s) == 0x6600);

    uint i = 0xFFBBCCAA;
    assert(invert(i) == 0xAACCBBFF);
    i = 0x12340000;
    assert(invert(i) == 0x3412);
    i = 0x1234;
    assert(invert(i) == 0x34120000);

    ulong l = 0xAABBCCDD_EEFF1122;
    assert(invert(l) == 0x2211FFEE_DDCCBBAA);
    l = 0xAABBCCDD_00000000;
    assert(invert(l) == 0xDDCCBBAA);
    l = 0xAABBCCDD;
    assert(invert(l) == 0xDDCCBBAA_00000000);

    ubyte[] a = [1];
    invert(&a[0], a.length);
    assert(a == [1]);

    a = [1, 2];
    invert(&a[0], a.length);
    assert(a == [2, 1]);

    a = [1, 2, 3, 4];
    invert(&a[0], a.length);
    assert(a == [4, 3, 2, 1]);

    a = [1, 2, 3, 4, 5, 6, 7, 8];
    invert(&a[0], a.length);
    assert(a == [8, 7, 6, 5, 4, 3, 2, 1]);

    a = [1, 2, 3];
    invert(&a[0], a.length);
    assert(a == [3, 2, 1]);

    a = [1, 2, 3, 4, 5];
    invert(&a[0], a.length);
    assert(a == [5, 4, 3, 2, 1]);

    a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    invert(&a[0], a.length);
    assert(a == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
}