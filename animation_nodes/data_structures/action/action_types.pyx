from cpython cimport PyMem_Malloc, PyMem_Free
from ... graphics import Rectangle

cdef class EvaluateFunctionData:
    cdef EvaluateFunction function
    cdef list channels



# Base Action
#######################################################

cdef class BoundedAction(Action):
    cdef BoundedActionEvaluator getEvaluator_Limited(self, list channels):
        defaults = FloatList.fromValue(0, length = len(channels))
        return self.getEvaluator_Full(channels, defaults)

    cpdef BoundedActionEvaluator getEvaluator_Full(self, list channels, FloatList defaults):
        if len(channels) != defaults.length:
            raise Exception("unequal channel and default amount")

        cdef set myChannels = self.getChannelSet()
        if all([channel in myChannels for channel in channels]):
            return self.getEvaluator_Limited(channels)
        else:
            return FilledBoundedActionEvaluator(self, channels, defaults)

    def __repr__(self):
        cdef set channels = self.getChannelSet()
        text = "Bounded Action with {} channels:\n".format(len(channels))
        for channel in sorted(channels, key = str):
            text += "    {}\n".format(channel)
        return text

# Base Evaluator
#######################################################

cdef class BoundedActionEvaluator(ActionEvaluator):
    cdef void evaluateBounded(self, float t, Py_ssize_t index, float *target):
        cdef float frame = t * self.getLength(index) + self.getStart(index)
        self.evaluate(frame, index, target)

    cpdef float getStart(self, Py_ssize_t index):
        return self.getEnd(index) - self.getLength(index)

    cpdef float getEnd(self, Py_ssize_t index):
        return self.getStart(index) + self.getLength(index)

    cpdef float getLength(self, Py_ssize_t index):
        return self.getEnd(index) - self.getStart(index)

    def drawPreview(self, Py_ssize_t index, rectangle):
        subRec = rectangle.getClampedSubFrameRange(self.getStart(index), self.getEnd(index))
        if subRec.width > 0:
            subRec.draw(color = (0.9, 0.9, 0.9, 1))

# Fill
#######################################################

cdef class FilledBoundedActionEvaluator(BoundedActionEvaluator):
    cdef:
        FloatList evaluatorTarget
        FloatList defaults
        IntegerList defaultMapping
        IntegerList evaluatorMapping
        BoundedActionEvaluator evaluator

    def __cinit__(self, BoundedAction source, list channels, FloatList defaults):
        self.channelAmount = len(channels)

        cdef list evaluatorChannels = []
        self.defaultMapping = IntegerList()
        self.evaluatorMapping = IntegerList()

        cdef Py_ssize_t i, j
        cdef set sourceChannels = source.getChannelSet()
        for i, channel in enumerate(channels):
            if channel in sourceChannels:
                evaluatorChannels.append(channel)
                self.evaluatorMapping.append(i)
            else:
                self.defaultMapping.append(i)

        self.defaults = defaults
        self.evaluator = source.getEvaluator(evaluatorChannels)
        self.evaluatorTarget = FloatList(length = len(evaluatorChannels))

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame, index, self.evaluatorTarget.data)

        cdef Py_ssize_t i
        for i in range(self.evaluatorMapping.length):
            target[self.evaluatorMapping.data[i]] = self.evaluatorTarget.data[i]

        cdef Py_ssize_t j
        for i in range(self.defaultMapping.length):
            j = self.defaultMapping.data[i]
            target[j] = self.defaults.data[j]

    cpdef float getStart(self, Py_ssize_t index):
        return self.evaluator.getStart(index)

    cpdef float getEnd(self, Py_ssize_t index):
        return self.evaluator.getEnd(index)

    cpdef float getLength(self, Py_ssize_t index):
        return self.evaluator.getLength(index)



# Remap
##################################################

cdef class RemapBoundedActionEvaluator(BoundedActionEvaluator):
    cdef BoundedActionEvaluator evaluator
    cdef IntegerList mapping
    cdef FloatList target

    def __cinit__(self, BoundedActionEvaluator evaluator,
                        list evaluatedChannels, list requiredChannels):
        self.evaluator = evaluator
        self.channelAmount = len(requiredChannels)
        self.mapping = IntegerList(length = self.channelAmount)
        self.target = FloatList(length = len(evaluatedChannels))

        cdef Py_ssize_t i
        for i in range(self.channelAmount):
            self.mapping.data[i] = evaluatedChannels.index(requiredChannels[i])

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame, index, self.target.data)

        cdef Py_ssize_t i
        for i in range(self.channelAmount):
            target[i] = self.target.data[self.mapping.data[i]]

    cpdef float getStart(self, Py_ssize_t index):
        return self.evaluator.getStart(index)

    cpdef float getEnd(self, Py_ssize_t index):
        return self.evaluator.getEnd(index)

    cpdef float getLength(self, Py_ssize_t index):
        return self.evaluator.getLength(index)


# Simple
###########################################################

cdef class SimpleBoundedAction(BoundedAction):
    cdef list getEvaluateFunctions(self):
        raise NotImplementedError()

    cdef newFunction(self, void *function, list channels):
        cdef EvaluateFunctionData data = EvaluateFunctionData()
        data.function = <EvaluateFunction>function
        data.channels = channels
        return data

    cdef set getChannelSet(self):
        cdef set channels = set()
        cdef EvaluateFunctionData data
        for data in self.getEvaluateFunctions():
            channels.update(data.channels)
        return channels

    cdef float getStart(self, Py_ssize_t index):
        raise NotImplementedError()

    cdef float getEnd(self, Py_ssize_t index):
        raise NotImplementedError()

    cdef float getLength(self, Py_ssize_t index):
        raise NotImplementedError()

    cdef BoundedActionEvaluator getEvaluator_Limited(self, list channels):
        return BoundedSimpleActionEvaluator(self, channels)

cdef class BoundedSimpleActionEvaluator(BoundedActionEvaluator):
    cdef SimpleBoundedAction action
    cdef EvaluateFunction *functions
    cdef IntegerList channelAmounts
    cdef IntegerList mapping
    cdef FloatList target

    def __cinit__(self, SimpleBoundedAction action, list channels):
        cdef list requiredFunctions = []
        cdef set requiredChannels = set(channels)
        cdef list targetChannels = []
        cdef EvaluateFunctionData data

        for data in action.getEvaluateFunctions():
            if not requiredChannels.isdisjoint(data.channels):
                requiredFunctions.append(data)
                targetChannels.extend(data.channels)
        self.channelAmount = len(channels)

        cdef Py_ssize_t i
        self.functions = <EvaluateFunction*>PyMem_Malloc(sizeof(EvaluateFunction) * len(requiredFunctions))
        for i in range(len(requiredFunctions)):
            self.functions[i] = (<EvaluateFunctionData>requiredFunctions[i]).function

        self.channelAmounts = IntegerList.fromValues([len(data.channels) for data in requiredFunctions])

        self.mapping = IntegerList(length = self.channelAmount)
        for i in range(self.channelAmount):
            self.mapping.data[i] = targetChannels.index(channels[i])

        self.target = FloatList(length = len(targetChannels))
        self.action = action

    def __dealloc__(self):
        PyMem_Free(self.functions)

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        cdef Py_ssize_t i
        cdef Py_ssize_t pos = 0
        for i in range(self.channelAmounts.length):
            self.functions[i](<void*>self.action, frame, index, self.target.data + pos)
            pos += self.channelAmounts.data[i]

        for i in range(self.channelAmount):
            target[i] = self.target.data[self.mapping.data[i]]

    cpdef float getStart(self, Py_ssize_t index):
        return self.action.getStart(index)

    cpdef float getEnd(self, Py_ssize_t index):
        return self.action.getEnd(index)

    cpdef float getLength(self, Py_ssize_t index):
        return self.action.getLength(index)


# Delay
###########################################################

class DelayAction:
    def __new__(self, Action action, float delay, bint relative = False):
        if isinstance(action, BoundedAction):
            return DelayBoundedAction(action, delay, relative)
        elif isinstance(action, UnboundedAction):
            return DelayUnboundedAction(action, delay, relative)
        else:
            raise Exception("unknown action type")

cdef class DelayBoundedAction(BoundedAction):
    cdef BoundedAction action
    cdef float delay
    cdef bint relative

    def __cinit__(self, BoundedAction action, float delay, bint relative):
        self.action = action
        self.delay = delay
        self.relative = relative

    cdef set getChannelSet(self):
        return self.action.getChannelSet()

    cdef BoundedActionEvaluator getEvaluator_Limited(self, list channels):
        cdef BoundedActionEvaluator subEvaluator = self.action.getEvaluator_Limited(channels)
        if self.relative:
            return RelativeDelayBoundedActionEvaluator(subEvaluator, self.delay)
        else:
            return ConstantDelayBoundedActionEvaluator(subEvaluator, self.delay)

cdef class RelativeDelayBoundedActionEvaluator(BoundedActionEvaluator):
    cdef BoundedActionEvaluator evaluator
    cdef float delay

    def __cinit__(self, BoundedActionEvaluator evaluator, float delay):
        self.evaluator = evaluator
        self.delay = delay
        self.channelAmount = evaluator.channelAmount

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame - index * self.delay, index, target)

    cpdef float getStart(self, Py_ssize_t index):
        return self.evaluator.getStart(index) + index * self.delay

    cpdef float getEnd(self, Py_ssize_t index):
        return self.evaluator.getEnd(index) + index * self.delay

    cpdef float getLength(self, Py_ssize_t index):
        return self.evaluator.getLength(index)

    def drawPreview(self, Py_ssize_t index, rectangle):
        offset = self.delay * index
        rec = rectangle.copy()
        rec.startFrame -= offset
        rec.endFrame -= offset
        self.evaluator.drawPreview(index, rec)

cdef class ConstantDelayBoundedActionEvaluator(BoundedActionEvaluator):
    cdef BoundedActionEvaluator evaluator
    cdef float delay

    def __cinit__(self, BoundedActionEvaluator evaluator, float delay):
        self.evaluator = evaluator
        self.delay = delay
        self.channelAmount = evaluator.channelAmount

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame - self.delay, index, target)

    cpdef float getStart(self, Py_ssize_t index):
        return self.evaluator.getStart(index) + self.delay

    cpdef float getEnd(self, Py_ssize_t index):
        return self.evaluator.getEnd(index) + self.delay

    cpdef float getLength(self, Py_ssize_t index):
        return self.evaluator.getLength(index)

    def drawPreview(self, Py_ssize_t index, rectangle):
        rec = rectangle.copy()
        rec.startFrame -= self.delay
        rec.endFrame -= self.delay
        self.evaluator.drawPreview(index, rec)


# Base Action
#######################################################

cdef class UnboundedAction(Action):
    cdef UnboundedActionEvaluator getEvaluator_Limited(self, list channels):
        defaults = FloatList.fromValue(0, length = len(channels))
        return self.getEvaluator_Full(channels, defaults)

    cpdef UnboundedActionEvaluator getEvaluator_Full(self, list channels, FloatList defaults):
        if len(channels) != defaults.length:
            raise Exception("unequal channel and default amount")

        cdef set myChannels = self.getChannelSet()
        if all([channel in myChannels for channel in channels]):
            return self.getEvaluator_Limited(channels)
        else:
            return FilledUnboundedActionEvaluator(self, channels, defaults)

    def __repr__(self):
        cdef set channels = self.getChannelSet()
        text = "Unbounded Action with {} channels:\n".format(len(channels))
        for channel in sorted(channels, key = str):
            text += "    {}\n".format(channel)
        return text

# Base Evaluator
#######################################################

cdef class UnboundedActionEvaluator(ActionEvaluator):
    def drawPreview(self, Py_ssize_t index, rectangle):
        rectangle.draw(color = (0.7, 0.7, 0.7, 1))

# Fill
#######################################################

cdef class FilledUnboundedActionEvaluator(UnboundedActionEvaluator):
    cdef:
        FloatList evaluatorTarget
        FloatList defaults
        IntegerList defaultMapping
        IntegerList evaluatorMapping
        UnboundedActionEvaluator evaluator

    def __cinit__(self, UnboundedAction source, list channels, FloatList defaults):
        self.channelAmount = len(channels)

        cdef list evaluatorChannels = []
        self.defaultMapping = IntegerList()
        self.evaluatorMapping = IntegerList()

        cdef Py_ssize_t i, j
        cdef set sourceChannels = source.getChannelSet()
        for i, channel in enumerate(channels):
            if channel in sourceChannels:
                evaluatorChannels.append(channel)
                self.evaluatorMapping.append(i)
            else:
                self.defaultMapping.append(i)

        self.defaults = defaults
        self.evaluator = source.getEvaluator(evaluatorChannels)
        self.evaluatorTarget = FloatList(length = len(evaluatorChannels))

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame, index, self.evaluatorTarget.data)

        cdef Py_ssize_t i
        for i in range(self.evaluatorMapping.length):
            target[self.evaluatorMapping.data[i]] = self.evaluatorTarget.data[i]

        cdef Py_ssize_t j
        for i in range(self.defaultMapping.length):
            j = self.defaultMapping.data[i]
            target[j] = self.defaults.data[j]




# Remap
##################################################

cdef class RemapUnboundedActionEvaluator(BoundedActionEvaluator):
    cdef UnboundedActionEvaluator evaluator
    cdef IntegerList mapping
    cdef FloatList target

    def __cinit__(self, UnboundedActionEvaluator evaluator,
                        list evaluatedChannels, list requiredChannels):
        self.evaluator = evaluator
        self.channelAmount = len(requiredChannels)
        self.mapping = IntegerList(length = self.channelAmount)
        self.target = FloatList(length = len(evaluatedChannels))

        cdef Py_ssize_t i
        for i in range(self.channelAmount):
            self.mapping.data[i] = evaluatedChannels.index(requiredChannels[i])

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame, index, self.target.data)

        cdef Py_ssize_t i
        for i in range(self.channelAmount):
            target[i] = self.target.data[self.mapping.data[i]]



# Simple
###########################################################

cdef class SimpleUnboundedAction(UnboundedAction):
    cdef list getEvaluateFunctions(self):
        raise NotImplementedError()

    cdef newFunction(self, void *function, list channels):
        cdef EvaluateFunctionData data = EvaluateFunctionData()
        data.function = <EvaluateFunction>function
        data.channels = channels
        return data

    cdef set getChannelSet(self):
        cdef set channels = set()
        cdef EvaluateFunctionData data
        for data in self.getEvaluateFunctions():
            channels.update(data.channels)
        return channels


    cdef UnboundedActionEvaluator getEvaluator_Limited(self, list channels):
        return UnboundedSimpleActionEvaluator(self, channels)

cdef class UnboundedSimpleActionEvaluator(UnboundedActionEvaluator):
    cdef SimpleUnboundedAction action
    cdef EvaluateFunction *functions
    cdef IntegerList channelAmounts
    cdef IntegerList mapping
    cdef FloatList target

    def __cinit__(self, SimpleUnboundedAction action, list channels):
        cdef list requiredFunctions = []
        cdef set requiredChannels = set(channels)
        cdef list targetChannels = []
        cdef EvaluateFunctionData data

        for data in action.getEvaluateFunctions():
            if not requiredChannels.isdisjoint(data.channels):
                requiredFunctions.append(data)
                targetChannels.extend(data.channels)
        self.channelAmount = len(channels)

        cdef Py_ssize_t i
        self.functions = <EvaluateFunction*>PyMem_Malloc(sizeof(EvaluateFunction) * len(requiredFunctions))
        for i in range(len(requiredFunctions)):
            self.functions[i] = (<EvaluateFunctionData>requiredFunctions[i]).function

        self.channelAmounts = IntegerList.fromValues([len(data.channels) for data in requiredFunctions])

        self.mapping = IntegerList(length = self.channelAmount)
        for i in range(self.channelAmount):
            self.mapping.data[i] = targetChannels.index(channels[i])

        self.target = FloatList(length = len(targetChannels))
        self.action = action

    def __dealloc__(self):
        PyMem_Free(self.functions)

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        cdef Py_ssize_t i
        cdef Py_ssize_t pos = 0
        for i in range(self.channelAmounts.length):
            self.functions[i](<void*>self.action, frame, index, self.target.data + pos)
            pos += self.channelAmounts.data[i]

        for i in range(self.channelAmount):
            target[i] = self.target.data[self.mapping.data[i]]



# Delay
###########################################################

class DelayAction:
    def __new__(self, Action action, float delay, bint relative = False):
        if isinstance(action, BoundedAction):
            return DelayBoundedAction(action, delay, relative)
        elif isinstance(action, UnboundedAction):
            return DelayUnboundedAction(action, delay, relative)
        else:
            raise Exception("unknown action type")

cdef class DelayUnboundedAction(UnboundedAction):
    cdef UnboundedAction action
    cdef float delay
    cdef bint relative

    def __cinit__(self, UnboundedAction action, float delay, bint relative):
        self.action = action
        self.delay = delay
        self.relative = relative

    cdef set getChannelSet(self):
        return self.action.getChannelSet()

    cdef UnboundedActionEvaluator getEvaluator_Limited(self, list channels):
        cdef UnboundedActionEvaluator subEvaluator = self.action.getEvaluator_Limited(channels)
        if self.relative:
            return RelativeDelayUnboundedActionEvaluator(subEvaluator, self.delay)
        else:
            return ConstantDelayUnboundedActionEvaluator(subEvaluator, self.delay)

cdef class RelativeDelayUnboundedActionEvaluator(UnboundedActionEvaluator):
    cdef UnboundedActionEvaluator evaluator
    cdef float delay

    def __cinit__(self, UnboundedActionEvaluator evaluator, float delay):
        self.evaluator = evaluator
        self.delay = delay
        self.channelAmount = evaluator.channelAmount

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame - index * self.delay, index, target)


    def drawPreview(self, Py_ssize_t index, rectangle):
        offset = self.delay * index
        rec = rectangle.copy()
        rec.startFrame -= offset
        rec.endFrame -= offset
        self.evaluator.drawPreview(index, rec)

cdef class ConstantDelayUnboundedActionEvaluator(UnboundedActionEvaluator):
    cdef UnboundedActionEvaluator evaluator
    cdef float delay

    def __cinit__(self, UnboundedActionEvaluator evaluator, float delay):
        self.evaluator = evaluator
        self.delay = delay
        self.channelAmount = evaluator.channelAmount

    cdef void evaluate(self, float frame, Py_ssize_t index, float *target):
        self.evaluator.evaluate(frame - self.delay, index, target)


    def drawPreview(self, Py_ssize_t index, rectangle):
        rec = rectangle.copy()
        rec.startFrame -= self.delay
        rec.endFrame -= self.delay
        self.evaluator.drawPreview(index, rec)