class_name ThreadPool extends RefCounted

var _threads: Array[Thread]
var _mutex: Mutex
var _semaphore: Semaphore
var _task_queue: Array
var _running: bool = true

func _init(thread_count: int = 4):
    _mutex = Mutex.new()
    _semaphore = Semaphore.new()
    _threads = []
    _task_queue = []

    # Create and start worker threads
    for i in thread_count:
        var thread = Thread.new()
        thread.start(_worker_thread)
        _threads.append(thread)

func submit_task(callable: Callable, args: Array = []):
    _mutex.lock()
    _task_queue.append([callable, args])
    _mutex.unlock()
    _semaphore.post()

func get_thread_count():
    return _threads.size()

func _worker_thread():
    while _running:
        _semaphore.wait()

        _mutex.lock()
        if _task_queue.is_empty():
            _mutex.unlock()
            continue

        var task = _task_queue.pop_front()
        _mutex.unlock()

        if task:
            var callable = task[0]
            var args = task[1]
            callable.callv(args)

func wait_for_completion():
    while true:
        _mutex.lock()
        var is_empty = _task_queue.is_empty()
        _mutex.unlock()
        if is_empty:
            break
        OS.delay_msec(10)

func shutdown():
    _running = false
    for i in _threads.size():
        _semaphore.post()

    for thread in _threads:
        thread.wait_to_finish()

    _threads.clear()