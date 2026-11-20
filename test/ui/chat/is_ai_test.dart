import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model_mapper.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

void main() {
  group('AI 消息标记', () {
    test('SocketMessage 透传 isAi', () {
      final message = SocketMessage.fromJson({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'content': 'hello',
        'type': 0,
        'createdAt': 1700000000000,
        'isAi': true,
      });

      expect(message.isAi, isTrue);
    });

    test('旧服务端没有 isAi 时默认 false', () {
      final message = SocketMessage.fromJson({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'content': 'hello',
        'type': 0,
        'createdAt': 1700000000000,
      });

      expect(message.isAi, isFalse);
    });

    test('历史消息 ChatMessage → ChatUiModel 保留 isAi', () {
      final apiMessage = ChatMessage.fromJson({
        'id': 'm1',
        'content': 'hello',
        'type': 0,
        'createdAt': 1700000000000,
        'isAi': true,
      });

      final uiModel = ChatUiModelMapper.fromApiModel(apiMessage, 'c1');

      expect(uiModel.isAi, isTrue);
      expect(uiModel.toJson()['isAi'], isTrue);
      expect(ChatUiModel.fromJson(uiModel.toJson()).isAi, isTrue);
    });

    test('人工消息 isAi=false', () {
      final apiMessage = ChatMessage.fromJson({
        'id': 'm2',
        'content': 'hi',
        'type': 0,
        'createdAt': 1700000000000,
      });

      expect(ChatUiModelMapper.fromApiModel(apiMessage, 'c1').isAi, isFalse);
    });
  });
}
