// This task is inspired by Sharada Yeluri
// https://www.linkedin.com/posts/sharada-yeluri_chatgpt-agi-openai-activity-7286404473030094850-HnzB
//
// "Build a buffer manager for a 16K entry-deep buffer that is 128 bits wide,
// shared dynamically between 256 queues.
// The module should sustain one enqueue and one dequeue every cycle
// without stalls... Use SRAMs for linked list structures, and yes,
// the SRAMs have two-cycle read latencies..."

module sharada_yeluri_challenge
# (
    parameter buffer_width     = 128,
              buffer_depth     = 16 * 1024,
              num_queues       = 256,
              queue_id_width   = $clog2 (num_queues)
)
(
    input                         clock,
    input                         reset,

    input                         enqueue_valid,
    output                        enqueue_ready,
    input  [buffer_width   - 1:0] enqueue_data,
    input  [queue_id_width - 1:0] enqueue_queue_id,

    input                         dequeue_request_valid,
    output                        dequeue_request_ready,
    input  [queue_id_width - 1:0] dequeue_request_queue_id,

    output                        dequeue_data_valid,
    input                         dequeue_data_ready,
    output [buffer_width   - 1:0] dequeue_data,
    output [queue_id_width - 1:0] dequeue_data_queue_id
);

    // Do it!
    // Instead of valid/ready protocol
    // you can implement send/credit return protocol if you wish

endmodule

module testbench;

    // Don't forget to write a self-checking testbench!

endmodule
