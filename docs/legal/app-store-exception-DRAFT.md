# DRAFT: Additional permission for app store distribution (AGPL-3.0, section 7)

> **Status: draft, not in force.** This is not legal advice. It was drafted
> for the maintainer to review (KLD-076, 2026-11-01) and is one of two options
> compared in `docs/tasks/KLD-076-release-basics.md` (the other is dual
> licensing of the maintainer's own store builds). It only becomes part of
> Klunki's licence if the maintainer adopts it: move it to
> `LICENSE-EXCEPTION.md` in the repository root, reference it from `README.md`
> and the in-app licence page, and only after every copyright holder has agreed.
> Have a lawyer check it before relying on it.

---

## Klunki: additional permission for app store distribution

Klunki is free software: you can redistribute it and/or modify it under the
terms of the GNU Affero General Public License, version 3 ("AGPL"), as
published by the Free Software Foundation.

As an additional permission under section 7 of the AGPL, the copyright holders
of Klunki give you permission to convey the Program, or a work based on it, in
object code form through an app distribution service (for example the Apple
App Store, Apple TestFlight or Google Play), even though that service's terms
of service, usage rules, end user licence agreement or technical measures
(such as encryption, signing or copy protection) impose restrictions that the
AGPL would otherwise not allow, including where such a service prevents you
from providing Installation Information. This permission applies only if all
of the following conditions are met:

1. The Corresponding Source of the exact version you convey is available to
   everyone, at no charge and under the terms of the AGPL (with or without this
   permission), from a publicly accessible network server, for as long as you
   offer that version through the service.
2. The store listing or the app itself states that the app is licensed under
   the AGPL and where its Corresponding Source can be obtained.
3. You impose no restrictions of your own beyond those required by the
   service, and you do not use the service's terms to restrict anyone's rights
   to the Corresponding Source under the AGPL.

This permission covers only the parts of the Program whose copyright is held
by Klunki's copyright holders and that are licensed under the AGPL. It does not
change the licence of any third-party component (libraries, fonts, images or
other material); each of those keeps its own licence, and you must comply
with it separately.

If you modify Klunki, you may extend this permission to your version of the
work, but you are not obliged to do so. If you do not wish to do so, delete
this permission statement from your version.

---

## Precedents this draft is modelled on

- **Signal** (Open Whisper Systems), "Additional Permissions For Submission to
  Apple App Store" on GPLv3: permission to convey non-source executables
  through the Apple App Store, provided the GPLv3 is otherwise followed for the
  covered work, including making Corresponding Source available (section 6).
  Text: <https://scancode-licensedb.aboutcode.org/signal-gpl-3.0-exception.LICENSE>
- **Nextcloud iOS app**, `COPYING.iOS` (GPLv3 or later): the copyright holders
  will not pursue violations that arise only from conflicts between the GPL and
  the App Store terms, and they allow derived apps in the App Store provided the
  GPL is otherwise followed (source code and licence text are provided).
  <https://github.com/nextcloud/ios/blob/master/COPYING.iOS>
- **Bulwark Mail** (AGPL-3.0-only), Discussion #1113 "Consent request: let
  Bulwark Mobile ship through the App Store and Google Play" (2026): the closest
  model for this draft. It is a section 7 permission for app stores. The
  Corresponding Source must be on a public server at no charge, the listing or
  app must say where the source is, no further restrictions may be added, it
  covers only the AGPL parts, recipients may remove it, and every contributor's
  consent is collected before it takes effect.
  <https://github.com/orgs/bulwarkmail/discussions/1113>

The explicit mention of Installation Information follows a point raised in the
AGPL/iOS discussions: the "Installation Information" paragraphs of section 6
are the part that app stores make impossible to meet for User Products.
