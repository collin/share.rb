$LOAD_PATH.push File.join(__FILE__, "../..")
require "lib/share"
system("clear")
require "rspec"
require "shoulda-matchers"
# require "ruby-debug"

RSpec.configure do |config|
  config.color_enabled = true
  # config.filter_run focus:true
end

poem = open("spec/data/jabberwocky.txt").read.split(/\s+/)
def random_word
  poem.shuffle.first
end

# def test_random_op(type, initial=type.new)
#   make_doc = -> { {ops: [], result: initial} }
#   op_sets = (0..3).map{ make_doc.call }
#   client, client2, server = op_sets
#   (0..10).each do
#     doc = op_sets.shuffle.first
#     op, doc[:result] = type.generate_random_op(doc[:result])
#     doc[:ops].push op
#   end

#   check_snapshots_equal = -> (left, right) {
#     if type.respond_to?(:serialize)
#       type.serialize(left).should == type.serialize(b)
#     else
#       left.should == right
#     end
#   }

#   test_apply = -> (doc) {
#     s = initial
#     doc[:ops].each{|op| s = type.apply(s, op) }
#     check_snapshots_equal.call(s, doc[:result])
#   }

#   op_sets.each{|set| test_apply(set) }

#   if type.respond_to?(:invert)
#     test_invert = -> (doc, ops=doc[:ops]) {
#       snapshot = JSON.parse(JSON.stringify(doc[:result]))
#       ops.reverse.each do |op|
#         op_ = type.invert op
#         snapshot = type.apply snapshot, op_
#       end

#       check_snapshots_equal.call snapshot, initial
#     }
#     op_sets.each{|set| test_invert.call(set) }
#   end

#   if type.respond_to?(:compose)
#     compose = -> (doc) {
#       if doc.ops.length > 0
#         doc[:composed] = compose_list(type, doc[:ops])
#         check_snapshots_equal.call doc[:result], type.apply(initial, doc[:composed])
#       end
#     }
#     op_sets.each{|set| compose.call set}

#     if test_invert
#       op_sets.each do |set|
#         next unless set[:composed]      
#         test_invert.call set, [set[:composed]]
#       end
#     end

#     if client[:composed] && server[:composed]
#       server_, client_ = transform_x(type, server[:composed], client[:composed])

#       s_c = type.apply server[:result], client_
#       c_s = type.apply client[:result], server_

#       check_snapshots_equal s_c, c_s

#       # if type.tp2 and client2.composed?
#       #   # TP2 requires that T(op3, op1 . T(op2, op1)) == T(op3, op2 . T(op1, op2)).
#       #   lhs = type.transform client2.composed, (type.compose client.composed, server_), 'left'
#       #   rhs = type.transform client2.composed, (type.compose server.composed, client_), 'left'

#       #   assert.deepEqual lhs, rhs    end
#   end

#   if type.respond_to?(:prune)

#   end
# end

