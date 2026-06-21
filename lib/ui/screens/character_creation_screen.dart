import 'package:flutter/material.dart';

import '../../game/models/innate_attributes.dart';
import '../../game/repositories/game_definition_repository.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key, required this.repository});

  final GameDefinitionRepository repository;

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  PlayerGender _gender = PlayerGender.male;
  late InnateAttributes _attributes;

  @override
  void initState() {
    super.initState();
    _attributes = InnateAttributes.random();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('初入江湖')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '为这段故事中的自己取一个名字。天赋取自《东方故事》的八项先天资质。',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  hintText: '一至六个汉字',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateName,
                onFieldSubmitted: (_) => _beginStory(),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PlayerGender>(
                segments: [
                  for (final gender in PlayerGender.values)
                    ButtonSegment(
                      value: gender,
                      label: Text(gender.label),
                      icon: Icon(
                        gender == PlayerGender.male
                            ? Icons.male_outlined
                            : Icons.female_outlined,
                      ),
                    ),
                ],
                selected: {_gender},
                onSelectionChanged:
                    (selection) => setState(() => _gender = selection.single),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '先天资质',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '重新生成资质',
                    onPressed:
                        () => setState(
                          () => _attributes = InnateAttributes.random(),
                        ),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final attribute in InnateAttribute.values)
                    _AttributeTile(
                      attribute: attribute,
                      value: _attributes.valueFor(attribute),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '膂力影响攻击，定力影响防御，根骨与灵性决定初始气血和精神；悟性影响研习效率。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _beginStory,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('进入故事'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (!RegExp(r'^[\u3400-\u9FFF]{1,6}$').hasMatch(name)) {
      return '请输入一至六个汉字';
    }
    return null;
  }

  void _beginStory() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      widget.repository.createInitialState(
        playerName: _nameController.text.trim(),
        gender: _gender,
        attributes: _attributes,
      ),
    );
  }
}

class _AttributeTile extends StatelessWidget {
  const _AttributeTile({required this.attribute, required this.value});

  final InnateAttribute attribute;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(child: Text(attribute.label)),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
