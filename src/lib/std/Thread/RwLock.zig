//! A lock that supports one writer or many readers.
//! This API is for kernel threads, not evented I/O.
//! This API requires being initialized at runtime, and initialization
//! can fail. Once initialized, the core operations cannot fail.

impl: Impl = .{},

const RwLock = @This();
const std = @import("../std.zig");
const builtin = @import("builtin");
const assert = std.debug.assert;

pub const Impl = if (builtin.single_threaded)
    SingleThreadedRwLock
else if (std.Thread.use_pthreads)
    PthreadRwLock
else
    DefaultRwLock;

/// Attempts to obtain exclusive lock ownership.
/// Returns `true` if the lock is obtained, `false` otherwise.
pub fn tryLock(rwl: *RwLock) bool {
    return rwl.impl.tryLock();
}

/// Blocks until exclusive lock ownership is acquired.
pub fn lock(rwl: *RwLock) void {
    return rwl.impl.lock();
}

/// Releases a held exclusive lock.
/// Asserts the lock is held exclusively.
pub fn unlock(rwl: *RwLock) void {
    return rwl.impl.unlock();
}

/// Attempts to obtain shared lock ownership.
/// Returns `true` if the lock is obtained, `false` otherwise.
pub fn tryLockShared(rwl: *RwLock) bool {
    return rwl.impl.tryLockShared();
}

/// Blocks until shared lock ownership is acquired.
pub fn lockShared(rwl: *RwLock) void {
    return rwl.impl.lockShared();
}

/// Releases a held shared lock.
pub fn unlockShared(rwl: *RwLock) void {
    return rwl.impl.unlockShared();
}

/// Single-threaded applications use this for deadlock checks in
/// debug mode, and no-ops in release modes.
pub const SingleThreadedRwLock = struct {
    state: enum { unlocked, locked_exclusive, locked_shared } = .unlocked,
    shared_count: usize = 0,

    /// Attempts to obtain exclusive lock ownership.
    /// Returns `true` if the lock is obtained, `false` otherwise.
    pub fn tryLock(rwl: *SingleThreadedRwLock) bool {
        switch (rwl.state) {
            .unlocked => {
                assert(rwl.shared_count == 0);
                rwl.state = .locked_exclusive;
                return true;
            },
            .locked_exclusive, .locked_shared => return false,
        }
    }

    /// Blocks until exclusive lock ownership is acquired.
    pub fn lock(rwl: *SingleThreadedRwLock) void {
        assert(rwl.state == .unlocked); // deadlock detected
        assert(rwl.shared_count == 0); // corrupted state detected
        rwl.state = .locked_exclusive;
    }

    /// Releases a held exclusive lock.
    /// Asserts the lock is held exclusively.
    pub fn unlock(rwl: *SingleThreadedRwLock) void {
        assert(rwl.state == .locked_exclusive);
        assert(rwl.shared_count == 0); // corrupted state detected
        rwl.state = .unlocked;
    }

    /// Attempts to obtain shared lock ownership.
    /// Returns `true` if the lock is obtained, `false` otherwise.
    pub fn tryLockShared(rwl: *SingleThreadedRwLock) bool {
        switch (rwl.state) {
            .unlocked => {
                rwl.state = .locked_shared;
                assert(rwl.shared_count == 0);
                rwl.shared_count = 1;
                return true;
            },
            .locked_exclusive, .locked_shared => return false,
        }
    }

    /// Blocks until shared lock ownership is acquired.
    pub fn lockShared(rwl: *SingleThreadedRwLock) void {
        switch (rwl.state) {
            .unlocked => {
                rwl.state = .locked_shared;
                assert(rwl.shared_count == 0);
                rwl.shared_count = 1;
            },
            .locked_shared => {
                rwl.shared_count += 1;
            },
            .locked_exclusive => unreachable, // deadlock detected
        }
    }

    /// Releases a held shared lock.
    pub fn unlockShared(rwl: *SingleThreadedRwLock) void {
        switch (rwl.state) {
            .unlocked => unreachable, // too many calls to `unlockShared`
            .locked_exclusive => unreachable, // exclusively held lock
            .locked_shared => {
                rwl.shared_count -= 1;
                if (rwl.shared_count == 0) {
                    rwl.state = .unlocked;
                }
            },
        }
    }
};

pub const PthreadRwLock = struct {
    rwlock: std.c.pthread_rwlock_t = .{},

    pub fn tryLock(rwl: *PthreadRwLock) bool {
        return std.c.pthread_rwlock_trywrlock(&rwl.rwlock) == .SUCCESS;
    }

    pub fn lock(rwl: *PthreadRwLock) void {
        const rc = std.c.pthread_rwlock_wrlock(&rwl.rwlock);
        assert(rc == .SUCCESS);
    }

    pub fn unlock(rwl: *PthreadRwLock) void {
        const rc = std.c.pthread_rwlock_unlock(&rwl.rwlock);
        assert(rc == .SUCCESS);
    }

    pub fn tryLockShared(rwl: *PthreadRwLock) bool {
        return std.c.pthread_rwlock_tryrdlock(&rwl.rwlock) == .SUCCESS;
    }

    pub fn lockShared(rwl: *PthreadRwLock) void {
        const rc = std.c.pthread_rwlock_rdlock(&rwl.rwlock);
        assert(rc == .SUCCESS);
    }

    pub fn unlockShared(rwl: *PthreadRwLock) void {
        const rc = std.c.pthread_rwlock_unlock(&rwl.rwlock);
        assert(rc == .SUCCESS);
    }
};

pub const DefaultRwLock = struct {
    state: usize = 0,
    mutex: std.Thread.Mutex = .{},
    semaphore: std.Thread.Semaphore = .{},

    const IS_WRITING: usize = 1;
    const WRITER: usize = 1 << 1;
    const READER: usize = 1 << (1 + std.meta.bitCount(Count));
    const WRITER_MASK: usize = std.math.maxInt(Count) << @ctz(usize, WRITER);
    const READER_MASK: usize = std.math.maxInt(Count) << @ctz(usize, READER);
    const Count = std.meta.Int(.unsigned, @divFloor(std.meta.bitCount(usize) - 1, 2));

    pub fn tryLock(rwl: *DefaultRwLock) bool {
        if (rwl.mutex.tryLock()) {
            const state = @atomicLoad(usize, &rwl.state, .SeqCst);
            if (state & READER_MASK == 0) {
                _ = @atomicRmw(usize, &rwl.state, .Or, IS_WRITING, .SeqCst);
                return true;
            }

            rwl.mutex.unlock();
        }

        return false;
    }

    pub fn lock(rwl: *DefaultRwLock) void {
        _ = @atomicRmw(usize, &rwl.state, .Add, WRITER, .SeqCst);
        rwl.mutex.lock();

        const state = @atomicRmw(usize, &rwl.state, .Or, IS_WRITING, .SeqCst);
        if (state & READER_MASK != 0)
            rwl.semaphore.wait();
    }

    pub fn unlock(rwl: *DefaultRwLock) void {
        _ = @atomicRmw(usize, &rwl.state, .And, ~IS_WRITING, .SeqCst);
        rwl.mutex.unlock();
    }

    pub fn tryLockShared(rwl: *DefaultRwLock) bool {
        const state = @atomicLoad(usize, &rwl.state, .SeqCst);
        if (state & (IS_WRITING | WRITER_MASK) == 0) {
            _ = @cmpxchgStrong(
                usize,
                &rwl.state,
                state,
                state + READER,
                .SeqCst,
                .SeqCst,
            ) orelse return true;
        }

        if (rwl.mutex.tryLock()) {
            _ = @atomicRmw(usize, &rwl.state, .Add, READER, .SeqCst);
            rwl.mutex.unlock();
            return true;
        }

        return false;
    }

    pub fn lockShared(rwl: *DefaultRwLock) void {
        var state = @atomicLoad(usize, &rwl.state, .SeqCst);
        while (state & (IS_WRITING | WRITER_MASK) == 0) {
            state = @cmpxchgWeak(
                usize,
                &rwl.state,
                state,
                state + READER,
                .SeqCst,
                .SeqCst,
            ) orelse return;
        }

        rwl.mutex.lock();
        _ = @atomicRmw(usize, &rwl.state, .Add, READER, .SeqCst);
        rwl.mutex.unlock();
    }

    pub fn unlockShared(rwl: *DefaultRwLock) void {
        const state = @atomicRmw(usize, &rwl.state, .Sub, READER, .SeqCst);

        if ((state & READER_MASK == READER) and (state & IS_WRITING != 0))
            rwl.semaphore.post();
    }
};
