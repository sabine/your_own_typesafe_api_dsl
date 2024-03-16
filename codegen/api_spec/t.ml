open Gen_types.Dsl

module T = struct
  let date_time = TypeName.of_string "DateTime"
  let user_id = TypeName.of_string "UserId"
  let user_cursor = TypeName.of_string "UserCursor"
  let conversation_id = TypeName.of_string "ConversationId"
  let conversation_cursor = TypeName.of_string "ConversationCursor"
  let line_id = TypeName.of_string "LineId"
end

module It = struct end

module Ot = struct
  let user = TypeName.of_string "User"
  let paginated_users = TypeName.of_string "PaginatedUsers"
  let conversation = TypeName.of_string "Conversation"
  let paginated_conversations = TypeName.of_string "PaginatedConversations"
  let parent_line = TypeName.of_string "ParentLine"
  let line = TypeName.of_string "Line"
  let thread = TypeName.of_string "Thread"
  let conversation_event = TypeName.of_string "ConversationEvent"
end
