IOR START
        fsync=1
        intraTestBarriers=1
        api=POSIX
        reorderTasksRandom=1
        verbose=0
        filePerProc=1
        interTestDelay=10
        blockSize=800g
        testFile = /gpfs/fs1/test
        transferSize=2m
        repetitions=1
        RUN
IOR STOP
