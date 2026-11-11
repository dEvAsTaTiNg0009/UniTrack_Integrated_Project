import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000/api',
);

void main() => runApp(const UniTrackApp());

class UniTrackApp extends StatelessWidget {
  const UniTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniTrack Student',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2563eb)),
        scaffoldBackgroundColor: const Color(0xfff5f7fb),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffdfe5ee)),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff2563eb), width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      home: const StudentHome(),
    );
  }
}

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final studentController = TextEditingController(text: 'STU001');
  final scoreController = TextEditingController(text: '75');
  Map<String, dynamic>? data;
  List<dynamic> interventions = const [];
  bool loading = false;
  String? error;
  double futureScore = 75;
  String? projection;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    studentController.dispose();
    scoreController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final id = studentController.text.trim().toUpperCase();
    if (id.isEmpty) {
      setState(() => error = 'Enter a student ID to view an academic profile.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      loading = true;
      error = null;
      data = null;
      interventions = const [];
      projection = null;
    });
    try {
      final responses = await Future.wait([
        http
            .get(Uri.parse('$apiBase/students/${Uri.encodeComponent(id)}'))
            .timeout(const Duration(seconds: 8)),
        http
            .get(Uri.parse(
                '$apiBase/interventions?student_id=${Uri.encodeComponent(id)}'))
            .timeout(const Duration(seconds: 8)),
      ]);
      if (responses[0].statusCode != 200) {
        throw Exception(responses[0].statusCode == 404
            ? 'Student ID not found. Try STU001 or another registered ID.'
            : 'The student profile could not be loaded.');
      }
      final profile = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final support = responses[1].statusCode == 200
          ? jsonDecode(responses[1].body) as List<dynamic>
          : <dynamic>[];
      if (!mounted) return;
      setState(() {
        data = profile;
        interventions = support;
      });
    } catch (exception) {
      if (!mounted) return;
      final message = exception.toString().replaceFirst('Exception: ', '');
      setState(() => error = message.contains('SocketException')
          ? 'Cannot reach the academic API. Start Express on port 3000 and try again.'
          : message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void calculateProjection() {
    final score = double.tryParse(scoreController.text.trim());
    final assessments = data?['assessments'] as List<dynamic>? ?? const [];
    if (score == null || score < 0 || score > 100) {
      setState(() => projection = 'Enter a future score between 0 and 100.');
      return;
    }
    if (assessments.isEmpty) {
      setState(() =>
          projection = 'A projection needs at least one existing assessment.');
      return;
    }
    final total = assessments.fold<double>(0, (sum, item) {
      return sum +
          number(item['marks_obtained']) / number(item['max_marks']) * 100;
    });
    final average = (total + score) / (assessments.length + 1);
    final attendance = number(data?['profile']?['average_attendance']);
    setState(() {
      futureScore = score;
      projection =
          'Projected average: ${average.toStringAsFixed(1)}%  |  ${riskFor(average, attendance)} risk';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          return Row(
            children: [
              if (!compact) const DesktopRail(),
              Expanded(child: buildPage(compact)),
            ],
          );
        },
      ),
    );
  }

  Widget buildPage(bool compact) {
    return Column(
      children: [
        TopBar(compact: compact, loading: loading, onRefresh: loadProfile),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                compact ? 16 : 34, 28, compact ? 16 : 34, 42),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pageHeading(compact),
                    const SizedBox(height: 24),
                    lookupCard(compact),
                    const SizedBox(height: 20),
                    if (loading) const LoadingPanel(),
                    if (error != null)
                      ErrorPanel(message: error!, onRetry: loadProfile),
                    if (!loading && error == null && data == null)
                      const EmptyPanel(),
                    if (!loading && error == null && data != null)
                      dashboard(compact),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget pageHeading(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STUDENT PORTAL',
                  style: TextStyle(
                      color: Color(0xff718099),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 7),
              Text('Your academic space',
                  style: TextStyle(
                      color: const Color(0xff14213d),
                      fontSize: compact ? 26 : 32,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text(
                  'Review your progress, attendance and next steps in one place.',
                  style: TextStyle(color: Color(0xff6b7890), fontSize: 13)),
            ],
          ),
        ),
        if (!compact)
          const Text('Live academic records',
              style: TextStyle(
                  color: Color(0xff2eaf78),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget lookupCard(bool compact) {
    final input = TextField(
      controller: studentController,
      textCapitalization: TextCapitalization.characters,
      onSubmitted: (_) => loadProfile(),
      decoration: const InputDecoration(
          prefixIcon: Icon(Icons.badge_outlined),
          hintText: 'e.g. STU001',
          labelText: 'Student ID'),
    );
    final button = FilledButton.icon(
      onPressed: loading ? null : loadProfile,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.arrow_forward, size: 17),
      label: Text(loading ? 'Loading' : 'View profile'),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                lookupLabel(),
                const SizedBox(height: 10),
                input,
                const SizedBox(height: 10),
                button
              ])
            : Row(children: [
                lookupLabel(),
                const SizedBox(width: 22),
                Expanded(child: input),
                const SizedBox(width: 12),
                button
              ]),
      ),
    );
  }

  Widget lookupLabel() =>
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Student lookup',
            style: TextStyle(
                color: Color(0xff14213d),
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        SizedBox(height: 3),
        Text('Use your registered student ID',
            style: TextStyle(color: Color(0xff7c899d), fontSize: 11))
      ]);

  Widget dashboard(bool compact) {
    final profile = data!['profile'] as Map<String, dynamic>;
    final assessments = data!['assessments'] as List<dynamic>? ?? const [];
    final attendance = data!['attendance'] as List<dynamic>? ?? const [];
    final marks = number(profile['average_marks']);
    final attendanceAverage = number(profile['average_attendance']);
    final detailContent = compact
        ? Column(children: [
            whatIfCard(marks, attendanceAverage),
            const SizedBox(height: 16),
            assessmentCard(assessments),
            const SizedBox(height: 16),
            attendanceCard(attendance),
            const SizedBox(height: 16),
            supportCard()
          ])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 3,
                child: Column(children: [
                  assessmentCard(assessments),
                  const SizedBox(height: 16),
                  attendanceCard(attendance)
                ])),
            const SizedBox(width: 18),
            Expanded(
                flex: 2,
                child: Column(children: [
                  whatIfCard(marks, attendanceAverage),
                  const SizedBox(height: 16),
                  supportCard()
                ]))
          ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      profileHero(profile, compact),
      const SizedBox(height: 16),
      summaryCards(
          marks, attendanceAverage, assessments.length, interventions.length, compact),
      const SizedBox(height: 18),
      detailContent
    ]);
  }

  Widget profileHero(Map<String, dynamic> profile, bool compact) {
    final risk = profile['risk_level'].toString();
    final identity = Row(children: [
      CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xffdce9ff),
          child: Text(
              profile['student_name']
                  .toString()
                  .split(' ')
                  .map((part) => part[0])
                  .take(2)
                  .join(),
              style: const TextStyle(
                  color: Color(0xff2563eb), fontWeight: FontWeight.w800))),
      const SizedBox(width: 13),
      Flexible(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(profile['student_name'].toString(),
            style: const TextStyle(
                color: Color(0xff14213d),
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        const SizedBox(height: 4),
        Text(
            '${profile['student_id']}  |  ${profile['roll_no']}  |  ${profile['program']}  |  Semester ${profile['semester']}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff718099), fontSize: 11))
      ]))
    ]);
    final status = Row(mainAxisSize: MainAxisSize.min, children: [
      riskChip(risk),
      const SizedBox(width: 18),
      const Icon(Icons.verified_outlined, color: Color(0xff2eaf78), size: 17),
      const SizedBox(width: 5),
      const Text('Profile synced',
          style: TextStyle(
              color: Color(0xff547060),
              fontSize: 11,
              fontWeight: FontWeight.w700))
    ]);
    return Card(
        child: Padding(
            padding: EdgeInsets.all(compact ? 18 : 24),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [identity, const SizedBox(height: 14), status])
                : Row(children: [identity, const Spacer(), status])));
  }

  Widget riskChip(String risk) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
          color: riskColor(risk).withValues(alpha: .12),
          borderRadius: const BorderRadius.all(Radius.circular(30))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: riskColor(risk)),
        const SizedBox(width: 6),
        Text('$risk risk',
            style: TextStyle(
                color: riskColor(risk),
                fontSize: 12,
                fontWeight: FontWeight.w800))
      ]));

    Widget summaryCards(double marks, double attendance, int assessments,
      int support, bool compact) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: compact ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.45,
      children: [
        miniStat('Average marks', '${marks.toStringAsFixed(1)}%',
            Icons.bar_chart, const Color(0xff2563eb)),
        miniStat('Attendance', '${attendance.toStringAsFixed(1)}%',
            Icons.calendar_month, const Color(0xff0f9f92)),
        miniStat('Assessments', '$assessments', Icons.assignment_outlined,
            const Color(0xffe58a25)),
        miniStat('Support records', '$support', Icons.favorite_border,
            const Color(0xffd94b55)),
      ],
    );
  }

  Widget miniStat(String label, String value, IconData icon, Color color) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: const BorderRadius.all(Radius.circular(8))),
                  child: Icon(icon, size: 17, color: color)),
              const SizedBox(width: 9),
              Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xff718099), fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(value,
                        style: const TextStyle(
                            color: Color(0xff14213d),
                            fontWeight: FontWeight.w800,
                            fontSize: 16))
                  ]))
            ])));
  }

  Widget assessmentCard(List<dynamic> assessments) {
    final child = assessments.isEmpty
        ? const InlineEmpty(message: 'No assessment records yet.')
        : Column(
            children: assessments
                .map<Widget>((item) => assessmentRow(item))
                .toList());
    return sectionCard(
        'Assessment history',
        'Subject-wise marks from the Express API',
        Icons.assignment_outlined,
        child);
  }

  Widget assessmentRow(dynamic item) {
    final max = number(item['max_marks']);
    final marks = number(item['marks_obtained']);
    final percentage = max > 0 ? marks / max : 0.0;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Color(0xffe8f0ff),
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: const Icon(Icons.book_outlined,
                  color: Color(0xff2563eb), size: 17)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item['subject_name'].toString(),
                    style: const TextStyle(
                        color: Color(0xff26344d),
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 5),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        minHeight: 5,
                        value: percentage.clamp(0, 1),
                        backgroundColor: const Color(0xffedf1f7),
                        color: percentage >= .55
                            ? const Color(0xff2eaf78)
                            : const Color(0xffe58a25)))
              ])),
          const SizedBox(width: 14),
          Text('${marks.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Color(0xff14213d),
                  fontWeight: FontWeight.w800,
                  fontSize: 12))
        ]));
  }

  Widget attendanceCard(List<dynamic> attendance) {
    final child = attendance.isEmpty
        ? const InlineEmpty(message: 'No attendance records yet.')
        : Column(
            children:
                attendance.map<Widget>((item) => attendanceRow(item)).toList());
    return sectionCard(
        'Attendance by subject',
        'Keep an eye on the 65% and 75% thresholds',
        Icons.calendar_month_outlined,
        child);
  }

  Widget attendanceRow(dynamic item) {
    final percentage = number(item['attendance_percentage']);
    final color = percentage < 65
        ? const Color(0xffd94b55)
        : percentage < 75
            ? const Color(0xffe58a25)
            : const Color(0xff2eaf78);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(item['subject_name'].toString(),
                    style: const TextStyle(
                        color: Color(0xff26344d),
                        fontWeight: FontWeight.w700,
                        fontSize: 12))),
            Text('${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 12))
          ]),
          const SizedBox(height: 7),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  minHeight: 7,
                  value: (percentage / 100).clamp(0, 1),
                  backgroundColor: const Color(0xffedf1f7),
                  color: color)),
          const SizedBox(height: 4),
          Text(
              '${item['classes_attended']} of ${item['classes_held']} classes attended',
              style: const TextStyle(color: Color(0xff8793a7), fontSize: 10))
        ]));
  }

  Widget whatIfCard(double currentMarks, double attendance) {
    final children = <Widget>[
      Row(children: [
        const Expanded(
            child: Text('Future assessment score',
                style: TextStyle(
                    color: Color(0xff26344d),
                    fontWeight: FontWeight.w700,
                    fontSize: 12))),
        Text('${futureScore.toStringAsFixed(0)} / 100',
            style: const TextStyle(
                color: Color(0xff2563eb),
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ]),
      Slider(
          value: futureScore.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (value) {
            setState(() {
              futureScore = value;
              scoreController.text = value.toStringAsFixed(0);
              projection = null;
            });
          }),
      TextField(
          controller: scoreController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null && parsed >= 0 && parsed <= 100) {
              setState(() {
                futureScore = parsed;
                projection = null;
              });
            }
          },
          decoration: const InputDecoration(
              labelText: 'Enter another score', suffixText: '/ 100')),
      const SizedBox(height: 12),
      SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
              onPressed: calculateProjection,
              icon: const Icon(Icons.calculate_outlined, size: 17),
              label: const Text('Calculate projection'))),
      if (projection != null)
        Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(projection!,
                style: const TextStyle(
                    color: Color(0xff14213d),
                    fontWeight: FontWeight.w800,
                    fontSize: 12))),
      const SizedBox(height: 14),
      Text(
          'Current average ${currentMarks.toStringAsFixed(1)}% with ${attendance.toStringAsFixed(1)}% attendance. This is a simple projection, not a prediction.',
          style: const TextStyle(
              color: Color(0xff718099), fontSize: 10, height: 1.4)),
    ];
    return sectionCard(
        'What-if marks simulator',
        'See how one future assessment could change your average',
        Icons.auto_graph,
        Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }

  Widget supportCard() {
    final child = interventions.isEmpty
        ? const InlineEmpty(message: 'No support records for this profile.')
        : Column(
            children: interventions
                .map<Widget>((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xfffff1df),
                        child: Icon(Icons.chat_bubble_outline,
                            color: Color(0xffe58a25), size: 15)),
                    title: Text(item['intervention_type'].toString(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        item['reason']?.toString() ?? 'No reason provided',
                        style: const TextStyle(fontSize: 10)),
                    trailing: Text(item['intervention_status'].toString(),
                        style: TextStyle(
                            color: item['intervention_status'] == 'Completed'
                                ? const Color(0xff2eaf78)
                                : const Color(0xffe58a25),
                            fontSize: 10,
                            fontWeight: FontWeight.w800))))
                .toList());
    return sectionCard('Support history', 'Interventions recorded by faculty',
        Icons.favorite_border, child);
  }

  Widget sectionCard(
      String title, String subtitle, IconData icon, Widget child) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 31,
                    height: 31,
                    decoration: const BoxDecoration(
                        color: Color(0xffe8f0ff),
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    child: Icon(icon, color: const Color(0xff2563eb), size: 16)),
                const SizedBox(width: 9),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: const TextStyle(
                              color: Color(0xff14213d),
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xff8793a7), fontSize: 10))
                    ]))
              ]),
              const SizedBox(height: 10),
              child
            ])));
  }
}

class TopBar extends StatelessWidget {
  final bool compact;
  final bool loading;
  final VoidCallback onRefresh;

  const TopBar(
      {required this.compact,
      required this.loading,
      required this.onRefresh,
      super.key});

  @override
  Widget build(BuildContext context) => Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffe6ebf2))),
      ),
      child: Row(children: [
        Text(compact ? 'UniTrack' : 'Student workspace / Overview',
            style: TextStyle(
                color:
                    compact ? const Color(0xff14213d) : const Color(0xff6b7890),
                fontSize: compact ? 20 : 13,
                fontWeight: compact ? FontWeight.w800 : FontWeight.normal)),
        const Spacer(),
        const Icon(Icons.cloud_done_outlined,
            color: Color(0xff2eaf78), size: 18),
        if (!compact)
          const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text('API connected',
                  style: TextStyle(color: Color(0xff547060), fontSize: 12))),
        const SizedBox(width: 12),
        IconButton(
            onPressed: loading ? null : onRefresh,
            tooltip: 'Refresh profile',
            icon: const Icon(Icons.refresh, size: 20)),
        const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xffdce9ff),
            child: Text('ST',
                style: TextStyle(
                    color: Color(0xff2563eb),
                    fontSize: 11,
                    fontWeight: FontWeight.w800)))
      ]));
}

class DesktopRail extends StatelessWidget {
  const DesktopRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 235,
      color: const Color(0xff14213d),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xff0f9f92),
                child: Text('U',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800))),
            SizedBox(width: 9),
            Text('UniTrack',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19)),
          ]),
          const SizedBox(height: 45),
          const Text('STUDENT PORTAL',
              style: TextStyle(
                  color: Color(0xff8e9bb1),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          railItem(Icons.grid_view_rounded, 'My overview', true),
          railItem(Icons.assignment_outlined, 'Assessments', false),
          railItem(Icons.calendar_month_outlined, 'Attendance', false),
          const Spacer(),
          const Divider(color: Color(0xff2d3b57)),
          const Text('Connected to faculty records',
              style: TextStyle(color: Color(0xff8e9bb1), fontSize: 10)),
        ],
      ),
    );
  }

  static Widget railItem(IconData icon, String label, bool active) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
          color: active ? const Color(0xff243553) : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(8))),
      child: Row(children: [
        Icon(icon,
            color: active ? Colors.white : const Color(0xffaab5c7), size: 18),
        const SizedBox(width: 11),
        Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xffaab5c7),
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500))
      ]));
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key});

  @override
  Widget build(BuildContext context) => const Card(
      child: Padding(
          padding: EdgeInsets.all(44),
          child: Center(
              child: Column(children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Loading your academic records...',
                style: TextStyle(color: Color(0xff6b7890), fontSize: 12))
          ]))));
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorPanel({required this.message, required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined,
                  color: Color(0xffd94b55), size: 34),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xff526078), fontSize: 13)),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(44),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_rounded, color: Color(0xff8e9bb1), size: 34),
              SizedBox(height: 10),
              Text('Enter your student ID to begin',
                  style: TextStyle(
                      color: Color(0xff526078), fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Your marks and attendance will appear here.',
                  style: TextStyle(color: Color(0xff8793a7), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineEmpty extends StatelessWidget {
  final String message;

  const InlineEmpty({required this.message, super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(message,
          style: const TextStyle(color: Color(0xff8793a7), fontSize: 11)));
}

double number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
String riskFor(double marks, double attendance) => marks < 40 || attendance < 65
    ? 'High'
    : marks < 55 || attendance < 75
        ? 'Medium'
        : 'Low';
Color riskColor(String risk) => risk == 'High'
    ? const Color(0xffd94b55)
    : risk == 'Medium'
        ? const Color(0xffd78a1f)
        : const Color(0xff2eaf78);
