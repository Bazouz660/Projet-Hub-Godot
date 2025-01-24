extends Node


var enemies = [1, 2, 3] # An array to be filled with enemies.

func worker_func():
	print("Worker function started.")
	# Expensive logic...

func _process(delta):
	var task_id = WorkerThreadPool.add_task(worker_func)
	# Other code...
	WorkerThreadPool.wait_for_task_completion(task_id)
	# Other code that depends on the enemy AI already being processed.