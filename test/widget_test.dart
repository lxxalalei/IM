import 'package:feishu_im/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the message workspace shell', (tester) async {
    await tester.pumpWidget(const FeishuImApp());

    expect(find.text('消息'), findsWidgets);
    expect(find.text('搜索联系人、群聊、聊天记录'), findsOneWidget);
    expect(find.text('千里马'), findsWidgets);
    expect(find.text('发送给 千里马'), findsOneWidget);
    expect(find.text('我接受了你的联系人申请，开始聊天吧！'), findsWidgets);
  });

  testWidgets('opens the contacts workspace', (tester) async {
    await tester.pumpWidget(const FeishuImApp());

    await tester.tap(find.text('通讯录'));
    await tester.pump();

    expect(find.text('联系人资料'), findsOneWidget);
    expect(find.text('阿拉蕾'), findsWidgets);
    expect(find.text('产品研发部 · AI 助手'), findsWidgets);
  });
}
