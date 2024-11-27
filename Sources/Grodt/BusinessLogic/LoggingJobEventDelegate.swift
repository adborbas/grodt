import Queues

struct LoggingJobEventDelegate: AsyncJobEventDelegate {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }

    func dispatched(job: JobEventData) async throws {
        logger.info("job: \(job.id) dispacthed at \(job.queuedAt)")
    }
    
    func didDequeue(jobId: String) async throws {
        logger.info("job: \(jobId) dequeued at \(Date())")
    }
    
    func success(jobId: String) async throws {
        logger.info("job: \(jobId) successful at \(Date())")
    }
    
    func error(jobId: String, error: any Error) async throws {
        logger.error("job \(jobId) failed with error: \(error)")
    }
}
