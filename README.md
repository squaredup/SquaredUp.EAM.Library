# SquaredUp.EAM.Library

## What is the Enterprise Application Monitoring MP

The Squared Up Enterprise Application Monitoring (EAM) SCOM Management Packs (MPs) add functionality to SCOM required by Squared Up's EAM and EAM Plus features.

Squared Up contains functionality that allows the saving of applications as Enterprise Applications (EAs), which are essentially SCOM Distributed Applications done right. The EAM Library management pack contains base classes, discoveries and monitors from which application specific management packs are created after mapping an app in Squared Up using the Visual Application Discovery and Analysis feature.

To make use of these Management packs, you will need SCOM installed and configured, monitoring your environment, and an instance of Squared Up licensed with EAM or EAM Plus.

## Getting Started

This GitHub repository contains the source files. The sealed downloadable management packs can be found here:

<https://download.squaredup.com/#managementpacks>

To install the EAM Library MPs you will need:

* SCOM 2012 R2 or higher
* SCOM Admin rights (only Administrators can import management packs)

## Install the SCOM Management pack

Import the management packs into SCOM using the standard process.

The MPs will show up as `Squared Up Enterprise Application Monitoring Library` (this is a sealed pack) and `Squared Up Enterprise Application Monitoring Overrides`. The Overrides pack is unsealed and contains some sensible defaults. Once imported into your environment it should not be overwritten unless you are happy to lose any overrides you may have created in this pack yourself.

## Management Pack Contents

By itself, these management packs do not enable any workloads or effect your SCOM management group. It is simply used as a source for base classes, and contains monitors and discoveries targeting those base classes.

The Overrides pack contains a group named `EAM_Default availability test clients` which will contain your SCOM RMS emulator by default.  It also contains an SLA named `Enterprise Application Health SLA` which is used on some Squared Up dashboards and perspectives shipped with the product.  Both can be safely customized to your needs.

## Releases

While anyone is free to download and import these management pack projects, sealed and signed releases of these management packs will only be available via <https://download.squaredup.com/#managementpacks>.

Releases of these management packs will use semantic versioning, and will occur as and when warranted.

## Help and Assistance

These management packs are originally developed by Squared Up (<http://www.squaredup.com>).

For help and advice, post questions on <http://community.squaredup.com/answers> or contact Squared Up support directly at <mailto:support@squaredup.com>.

If you have found a specific bug or issue with one of the management packs, please raise an [issue](https://github.com/squaredup/SquaredUp.EAM.Library/issues) on GitHub.
