import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/url/url_bloc.dart';
import '../../../../bloc/url/url_event.dart';
import '../../../../bloc/url/url_state.dart';
import '../../../../models/url_model.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/inline_alert.dart';
import '../../../layout/breakpoints.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/link_rules.dart';
import '../cubit/alias_check_cubit.dart';
import 'alias_field.dart';

class CreateLinkPanel extends StatefulWidget {
  final String domainPrefix;
  final ValueChanged<UrlModel> onCreated;

  const CreateLinkPanel({super.key, required this.domainPrefix, required this.onCreated});

  @override
  State<CreateLinkPanel> createState() => _CreateLinkPanelState();
}

class _CreateLinkPanelState extends State<CreateLinkPanel> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _aliasController = TextEditingController();
  final _urlFocus = FocusNode(debugLabel: 'create-url');
  bool _customize = false;
  bool _submitted = false;
  String? _serverError;

  @override
  void dispose() {
    _urlController.dispose();
    _aliasController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<UrlBloc>();
    if (bloc.state is UrlCreating) return;

    // Accept bare domains ("example.com/x") by adding https://.
    final normalized = LinkRules.normalizeUrl(_urlController.text);
    if (normalized != _urlController.text) _urlController.text = normalized;

    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final alias = _aliasController.text.trim().toLowerCase();
    if (alias.isNotEmpty && context.read<AliasCheckCubit>().state.blocksSubmit) {
      setState(() => _customize = true);
      return;
    }

    bloc.add(CreateUrlRequested(originalUrl: normalized, customAlias: alias.isEmpty ? null : alias));
  }

  void _onUrlState(BuildContext context, UrlState state) {
    if (state is UrlActionSuccess && state.action == UrlAction.create && state.created != null) {
      // Clear only after the server accepted the link, so errors keep the input.
      _urlController.clear();
      _aliasController.clear();
      context.read<AliasCheckCubit>().reset();
      setState(() {
        _submitted = false;
        _customize = false;
      });
      widget.onCreated(state.created!);
    } else if (state is UrlError && state.action == UrlAction.create) {
      setState(() => _serverError = state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final creating = context.select<UrlBloc, bool>((b) => b.state is UrlCreating);

    final urlField = Semantics(
      label: 'Destination URL',
      child: TextFormField(
        controller: _urlController,
        focusNode: _urlFocus,
        autofocus: context.isDesktop,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        enableSuggestions: false,
        onFieldSubmitted: (_) => _submit(),
        autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        validator: (v) => LinkRules.urlError(v ?? ''),
        style: t.body.copyWith(fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'Paste a long URL, e.g. https://example.com/very/long/path',
          prefixIcon: Icon(Icons.link_rounded, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: Space.s3, vertical: 14),
        ),
      ),
    );

    final shorten = AppButton(label: 'Shorten', icon: Icons.bolt_rounded, loading: creating, onPressed: _submit);

    return BlocListener<UrlBloc, UrlState>(
      listener: _onUrlState,
      child: AppCard(
        padding: const EdgeInsets.all(Space.s6),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create a short link', style: t.h2),
              const SizedBox(height: Space.s1),
              Text('Paste a URL, optionally pick an alias, and share it anywhere.', style: t.small),
              const SizedBox(height: Space.s5),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        urlField,
                        const SizedBox(height: Space.s3),
                        SizedBox(height: 44, child: shorten),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: urlField),
                      const SizedBox(width: Space.s3),
                      SizedBox(height: 48, child: shorten),
                    ],
                  );
                },
              ),
              const SizedBox(height: Space.s3),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _customize = !_customize),
                  style: TextButton.styleFrom(
                    foregroundColor: c.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: Space.s2),
                  ),
                  icon: AnimatedRotation(
                    turns: _customize ? 0.25 : 0,
                    duration: Motion.fast,
                    child: const Icon(Icons.chevron_right_rounded, size: 18),
                  ),
                  label: Text(_customize ? 'Hide options' : 'Customize link'),
                ),
              ),
              AnimatedSize(
                duration: Motion.medium,
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: _customize
                    ? Padding(
                        padding: const EdgeInsets.only(top: Space.s3),
                        child: AliasField(
                          controller: _aliasController,
                          domainPrefix: widget.domainPrefix,
                          onSubmitted: (_) => _submit(),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (_serverError != null) ...[const SizedBox(height: Space.s4), InlineAlert(_serverError!)],
            ],
          ),
        ),
      ),
    );
  }
}
