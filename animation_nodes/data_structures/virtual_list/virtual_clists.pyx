cimport cython

cdef class VirtualVector3DList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, Vector3DList):
            return cls.fromList(obj, default)
        else:
            return VirtualVector3DList_Element(obj)

    @classmethod
    def fromList(cls, Vector3DList realList, default):
        if realList.length == 0:
            return VirtualVector3DList_Element(default)
        elif realList.length == 1:
            return VirtualVector3DList_Element(realList[0], realLength = 1)
        else:
            return VirtualVector3DList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualVector3DList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualVector3DList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef Vector3DList newList = Vector3DList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)[0]
        return newList

    cdef Vector3 * get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualVector3DList_List(VirtualVector3DList):
    cdef Vector3DList realList
    cdef Vector3 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, Vector3DList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef Vector3 * get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualVector3DList_Element(VirtualVector3DList):
    cdef Vector3DList realList
    cdef Vector3 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = Vector3DList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef Vector3 * get(self, Py_ssize_t i):
        return (self.realData)

    def getRealLength(self):
        return self.realLength


cdef class VirtualMatrix4x4List(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, Matrix4x4List):
            return cls.fromList(obj, default)
        else:
            return VirtualMatrix4x4List_Element(obj)

    @classmethod
    def fromList(cls, Matrix4x4List realList, default):
        if realList.length == 0:
            return VirtualMatrix4x4List_Element(default)
        elif realList.length == 1:
            return VirtualMatrix4x4List_Element(realList[0], realLength = 1)
        else:
            return VirtualMatrix4x4List_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualMatrix4x4List_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualMatrix4x4List.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef Matrix4x4List newList = Matrix4x4List(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)[0]
        return newList

    cdef Matrix4 * get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualMatrix4x4List_List(VirtualMatrix4x4List):
    cdef Matrix4x4List realList
    cdef Matrix4 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, Matrix4x4List realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef Matrix4 * get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualMatrix4x4List_Element(VirtualMatrix4x4List):
    cdef Matrix4x4List realList
    cdef Matrix4 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = Matrix4x4List.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef Matrix4 * get(self, Py_ssize_t i):
        return (self.realData)

    def getRealLength(self):
        return self.realLength


cdef class VirtualEulerList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, EulerList):
            return cls.fromList(obj, default)
        else:
            return VirtualEulerList_Element(obj)

    @classmethod
    def fromList(cls, EulerList realList, default):
        if realList.length == 0:
            return VirtualEulerList_Element(default)
        elif realList.length == 1:
            return VirtualEulerList_Element(realList[0], realLength = 1)
        else:
            return VirtualEulerList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualEulerList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualEulerList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef EulerList newList = EulerList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)[0]
        return newList

    cdef Euler3 * get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualEulerList_List(VirtualEulerList):
    cdef EulerList realList
    cdef Euler3 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, EulerList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef Euler3 * get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualEulerList_Element(VirtualEulerList):
    cdef EulerList realList
    cdef Euler3 *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = EulerList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef Euler3 * get(self, Py_ssize_t i):
        return (self.realData)

    def getRealLength(self):
        return self.realLength


cdef class VirtualFloatList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, FloatList):
            return cls.fromList(obj, default)
        else:
            return VirtualFloatList_Element(obj)

    @classmethod
    def fromList(cls, FloatList realList, default):
        if realList.length == 0:
            return VirtualFloatList_Element(default)
        elif realList.length == 1:
            return VirtualFloatList_Element(realList[0], realLength = 1)
        else:
            return VirtualFloatList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualFloatList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualFloatList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef FloatList newList = FloatList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)
        return newList

    cdef float  get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualFloatList_List(VirtualFloatList):
    cdef FloatList realList
    cdef float *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, FloatList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef float  get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))[0]

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualFloatList_Element(VirtualFloatList):
    cdef FloatList realList
    cdef float *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = FloatList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef float  get(self, Py_ssize_t i):
        return (self.realData)[0]

    def getRealLength(self):
        return self.realLength


cdef class VirtualDoubleList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, DoubleList):
            return cls.fromList(obj, default)
        else:
            return VirtualDoubleList_Element(obj)

    @classmethod
    def fromList(cls, DoubleList realList, default):
        if realList.length == 0:
            return VirtualDoubleList_Element(default)
        elif realList.length == 1:
            return VirtualDoubleList_Element(realList[0], realLength = 1)
        else:
            return VirtualDoubleList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualDoubleList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualDoubleList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef DoubleList newList = DoubleList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)
        return newList

    cdef double  get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualDoubleList_List(VirtualDoubleList):
    cdef DoubleList realList
    cdef double *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, DoubleList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef double  get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))[0]

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualDoubleList_Element(VirtualDoubleList):
    cdef DoubleList realList
    cdef double *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = DoubleList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef double  get(self, Py_ssize_t i):
        return (self.realData)[0]

    def getRealLength(self):
        return self.realLength


cdef class VirtualLongList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, LongList):
            return cls.fromList(obj, default)
        else:
            return VirtualLongList_Element(obj)

    @classmethod
    def fromList(cls, LongList realList, default):
        if realList.length == 0:
            return VirtualLongList_Element(default)
        elif realList.length == 1:
            return VirtualLongList_Element(realList[0], realLength = 1)
        else:
            return VirtualLongList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualLongList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualLongList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef LongList newList = LongList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)
        return newList

    cdef long  get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualLongList_List(VirtualLongList):
    cdef LongList realList
    cdef long *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, LongList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef long  get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))[0]

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualLongList_Element(VirtualLongList):
    cdef LongList realList
    cdef long *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = LongList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef long  get(self, Py_ssize_t i):
        return (self.realData)[0]

    def getRealLength(self):
        return self.realLength


cdef class VirtualBooleanList(VirtualList):
    @classmethod
    def fromListOrElement(cls, obj, default):
        if isinstance(obj, BooleanList):
            return cls.fromList(obj, default)
        else:
            return VirtualBooleanList_Element(obj)

    @classmethod
    def fromList(cls, BooleanList realList, default):
        if realList.length == 0:
            return VirtualBooleanList_Element(default)
        elif realList.length == 1:
            return VirtualBooleanList_Element(realList[0], realLength = 1)
        else:
            return VirtualBooleanList_List(realList)

    @classmethod
    def fromElement(cls, element):
        return VirtualBooleanList_Element(element)

    @classmethod
    def createMultiple(cls, *elements):
        cdef list virtualLists = []
        for src, default in elements:
            virtualLists.append(VirtualBooleanList.fromListOrElement(src, default))
        return virtualLists

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        cdef BooleanList newList = BooleanList(length = length)
        cdef Py_ssize_t i
        for i in range(length):
            newList.data[i] = self.get(i)
        return newList

    cdef char  get(self, Py_ssize_t i):
        raise NotImplementedError()

cdef class VirtualBooleanList_List(VirtualBooleanList):
    cdef BooleanList realList
    cdef char *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, BooleanList realList):
        self.realList = realList
        self.realData = realList.data
        self.realLength = realList.length
        assert self.realLength > 0

    @cython.cdivision(True)
    cdef char  get(self, Py_ssize_t i):
        return (self.realData + (i % self.realLength))[0]

    def getRealLength(self):
        return self.realLength

    def materialize(self, Py_ssize_t length, bint canUseOriginal = False):
        if canUseOriginal and self.realLength == length:
            return self.realList
        else:
            return super().materialize(length, canUseOriginal)

cdef class VirtualBooleanList_Element(VirtualBooleanList):
    cdef BooleanList realList
    cdef char *realData
    cdef Py_ssize_t realLength

    def __cinit__(self, element, realLength = 0):
        self.realList = BooleanList.fromValue(element)
        self.realData = self.realList.data
        self.realLength = realLength

    cdef char  get(self, Py_ssize_t i):
        return (self.realData)[0]

    def getRealLength(self):
        return self.realLength
