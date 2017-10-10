#!/usr/bin/perl

# NB: this part of the eggnog source DEPENDS on wegn,
#     defined in another source code repo (n2t_create)

# xxx must test the ezid and oca and yamz production binders!!!
#      this only tests the non-prod stuff
# xxx add princeton test/NAAN check to redirect rules?
# xxx add test that inflection->cgi rewrite is working

use 5.010;
use Test::More;

use strict;
use warnings;

use File::ValueTester ':all';
use File::Value ':all';
use File::Temper 'etemper';

my $which = `which wegn`;
$which =~ /wegn/ or plan skip_all => "why: web client \"wegn\" not found";

grep(/\/blib\/lib/, @INC) and plan skip_all =>
    "why: should be run with installed code (eg, \"n2t test\" not with -Mblib)";

plan 'no_plan';		# how we usually roll -- freedom to test whatever

SKIP: {

my ($x, $y, $n);

my $ark1 = 'ark:/99999/fk8n2test1';
my $tgt1 = 'http://www.cdlib.org/';
my $tgt2 = 'http://www.cdlib.org/' . File::Temper::etemper();
my $eoi = 'doi:10.5072/EOITEST';	# MUST register in normalized uppercase
my $eoi_tgt = 'http://crossref.org/';
my $eoi_ref = 'eoi:10.5072/EOITEST';	# normalized reference
my $eoi_ref_lc = 'eoi:10.5072/eoitest';	# unnormalized reference

my $snachost = 'socialarchive.iath.virginia.edu';

# xxx add to t/apachebase.t
#         random timeofday value test for target to avoid effects
#         of having old values make tests pass that should fail

#my $srvbase_u = 'https://jak-macbook.local:18443';
#my $srvbase_u = 'http://jak-macbook.local:18880';
my $srvbase_u = 'http://localhost:18880';

# First test a simple mint.  Make sure to error out if server isn't even up.
$x = `wegn mint 1`;
$x =~ /failed.*refused/ and
	print("\n    ERROR: server isn't reachable!  Is it started?\n\n"),
	exit 1;
like $x, qr@99999/fk4\w\w\w@, "minted id matches format";

ok -f "$ENV{HOME}/warts/.pswdfile.n2t",
	"real passwords set up to occlude dummy passwords";

if ($ENV{EGNAPA_HOST_CLASS} eq 'prd') {

	# Some kludgy tests based on what is hopefully permanent data.
	# NB: these test read the redirect Location but don't follow it.

	print "--- BEGIN tests potentially affected by volatile data\n";

	$x = `wegn -v locate "ark:/87924/r4639m84b?embed=true"`;
	like $x, qr{^Location: https://repository.duke.edu/id/ark:/87924/r4639m84b\?embed=true}m,
		"Duke target redirect with SPT";

	# Location: http://merritt.cdlib.org/m/ark%3A%2F28722%2Fk2057s78h
	$x = `wegn -v locate "ark:/28722/k2057s78h"`;
	like $x, qr{^Location: http://merritt.cdlib.org/.*}m,
		"Merritt target redirect";

	# Location: http://bibnum.univ-lyon1.fr/nuxeo/nxfile/default/67ff978c-fd9b-4cef-8e44-5ce929ce1445/blobholder:0/THph_2015_CAYOT_Catherine.pdf
	$x = `wegn locate "ark:/47881/m6zw1j9d"`;
	like $x, qr{^Location: http://bibnum.*}m,
		"U Lyon target redirect";

	#  http://www.archive.org/details/testsandreagents031780mbp
	$x = `wegn -v locate "ark:/13960/t00000m0v"`;
	like $x, qr/^Location: http:.*testsandreagents031780mbp/m,
		"OCA target redirect";

	$x = `wegn locate "ark:/99152/h1023"`;
	like $x, qr{^Location: http://yamz.net/term/concept=h1023.*}m,
		"YAMZ target redirect";

	# xxx currently this perio.do works by SPT on a short id (.../p0)
	#     should it not work with a shoulder redirect rule?

	# Ryan Shaw, Eric Kansa ("periodo" ezid customers), with one
	# identifier (p0) in the 99152 namespace.
	$x = `wegn locate "ark:/99152/p0vn2frcz8h"`;
	like $x, qr{^Location: https://test.perio.do.*}m,
		"Perio.do target redirect";

	print "--- END tests potentially affected by volatile data\n";
}

#$x = `crontab -l`;
#like $x, qr/replicate/, 'crontab replicates periodically';
#
#like $x, qr/restart/, 'crontab restarts server periodically';

# yyy retire soon
my $home = $ENV{HOME};
$x = `$home/sv/cur/build/eggnog/replay`;
like $x, qr/usage/i, 'replay (replicate) script is executable';

# xxx pretty minimal test
$x = `$home/local/bin/n2t`;
like $x, qr/usage/i, 'n2t script is executable';

# xxx pretty minimal test
$x = `$home/n2t_create/admegn`;
like $x, qr/usage/i, 'admegn script is executable';

## xxx wegn is bad at setting multiple word values!
#$x = `wegn $ark1.set x "this is apostrophes test"`;
#like $x, qr/^egg-status: 0/m,
#	"egg sets value containing apostrophe";
#
#$x = `wegn $ark1.fetch`;
#like $x, qr/^xxx/m,
#	"egg fetches apostrophe in value";

$x = `wegn -v $ark1.set _t $tgt1`;
like $x, qr/^egg-status: 0/m,
	"egg sets target URL for id $ark1";

#exit;  ########

$x = `wegn locate "$ark1"`;
like $x, qr/^Location: \Q$tgt1/m, "bound target value resolved";

$x = `wegn $ark1.set _t $tgt2`;
like $x, qr/^egg-status: 0/m, "egg sets new target URL $tgt2";

$x = `wegn $ark1.fetch`;
like $x, qr/^_t: \Q$tgt2/m, "new bound target value fetched";

$x = `wegn locate "$ark1"`;
like $x, qr/^Location: \Q$tgt2/m, "new bound target value resolved";

#print "XXX first x=$x\n";	######################
#exit;

# we test 3 times in a row to make sure that one resolver process is
# sensitive to changes (unlike when we used to use DB_File)
$tgt2 .= 'a';		# another new value
$x = `wegn $ark1.set _t $tgt2`;
like $x, qr/^egg-status: 0/m, "egg sets second new target $tgt2";

$x = `wegn $ark1.fetch`;
like $x, qr/^_t: \Q$tgt2/m, "second new bound target value fetched";

$x = `wegn locate "$ark1"`;
like $x, qr/^Location: \Q$tgt2/m, "second new bound target value resolved";

$tgt2 .= 'b';		# another new value
$x = `wegn $ark1.set _t $tgt2`;
like $x, qr/^egg-status: 0/m, "egg sets third new target $tgt2";

$x = `wegn $ark1.fetch`;
like $x, qr/^_t: \Q$tgt2/m, "third new bound target value fetched";

$x = `wegn locate "$ark1"`;
like $x, qr/^Location: \Q$tgt2/m, "third new bound target value resolved";

#print "OK to ignore that test until BDB interface code deployed\n";

# These next tests ensure that the public documentation examples in 
# https://wiki.ucop.edu/display/DataCite/Suffix+Passthrough+Explained
# work for suffix passthrough.
#
# NB: these tests ACTUALLY CHANGE a live production database, but
# in harmless ways, actually ensuring the documentation is correct.
#
# NB: XXX these tests may not work on a new system until a server
#     reboot, due to resolver bug (remove this note when fixed)

my $cdl_ark = 'ark:/12345/fk1234';
my $cdl_tgt = 'http://www.cdlib.org/services';
my $cdl_ext = '/uc3/ezid/';

$x = `wegn $cdl_ark.set _t $cdl_tgt`;
like $x, qr/^egg-status: 0/m, "egg sets target for $cdl_ark";

$x = `wegn locate "$cdl_ark$cdl_ext"`;
like $x, qr/^Location: \Q$cdl_tgt$cdl_ext/m,
	"documented suffix passthrough works for cdl_ark $cdl_ark";
# xxx what's this next for?
$x = `wegn locate "$cdl_ark"`;

my $wkp_ark = 'ark:/12345/fk1235';
my $wkp_tgt = 'http://en.wikipedia.org/wiki';
my $wkp_ext = '/Persistent_identifier';

$x = `wegn $wkp_ark.set _t $wkp_tgt`;
like $x, qr/^egg-status: 0/m, "egg sets target for $wkp_ark";
$x = `wegn locate "$wkp_ark$wkp_ext"`;
like $x, qr/^Location: \Q$wkp_tgt$wkp_ext/m,
	"documented suffix passthrough works for wkp_ark $wkp_ark";

my $srch_ark = 'ark:/12345/fk3';
my $srch_tgt = 'http://www.google.com/#q=';
my $enc_srch_tgt = 'http://www.google.com/%23q=';	# encoded form
my $srch_ext = 'pqrst';
#xxx fix wiki doc (An e)xtended ARK: http://n2t.net/ark:/12345/fk3pqrst
#    high level intro could be simpler too

$x = `wegn $srch_ark.set _t "$enc_srch_tgt"`;
like $x, qr/^egg-status: 0/m, "egg sets target for $srch_ark";
$x = `wegn $srch_ark.fetch`;
# test not strictly needed, but this one's tricky with encoding
like $x, qr/^_t: \Q$srch_tgt/m, "bound target $srch_tgt fetched";
$x = `wegn locate "$srch_ark$srch_ext"`;
like $x, qr/^Location: \Q$srch_tgt$srch_ext/m,
	"documented suffix passthrough works for srch_ark $srch_ark";

# yyy temporary and redundant with first test ???
# There's no way to usefully test production minting right now.  Every
# minter currently in production use connects directly via hardcoded URL:
#
$x = `wegn mint 1`;
like $x, qr@99999/fk4\w\w\w@, "minted id matches format";

# comment out to reduce noise temporarily
my $prd = 'n2t.net';
#$x = `wegn -s $prd@@ ark:/99999/fk8n2test1.set foo bar`;
#like $x, qr@egg-status: 0@, "signed cert check on production permits binding";

# comment out to reduce noise temporarily
#my $stg = 'ids-n2t-stg.cdlib.org';
#$x = `wegn -s $stg@@ ark:/99999/fk8n2test1.set foo bar`;
#like $x, qr@egg-status: 0@, "signed cert check on stage permits binding";

use File::Binder ':all';
my $rrminfo = RRMINFOARK;

my $hgid = `hg identify | sed 's/ .*//'`;
chop $hgid;
#$x = `$wgcl "$srvbase_u/$rrminfo"`;
$x = `wegn locate "$rrminfo"`;
like $x, qr{Location:.*dvcsid=\Q$hgid\E&rmap=}i,
	'resolver info with correct dvcsid returned';

# see Resolver.pm for these, ($scheme_test, $scheme_target), something like
#      'xyzzytestertesty' => 'http://example.org/foo?gene=$id.zaf'
#
use File::Resolver ':all';
my ($i, $q, $target);

#($i, $q) = ('987654', '-z-?');
#$target = $File::Resolver::scheme_target;
#$target =~ s/\$id\b/$i/g;
#
# yyy this was meant to be an artificial test that didn't rely on actual
#     real prefix data, which is volatile and sort of unsuitable for
#     controlled testing
##$x = `wegn -v locate "$File::Resolver::scheme_test:$i?$q"`;
#$x = `wegn -v locate "$File::Resolver::scheme_test:$i"`;
##like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
#like $x, qr/response.*302 .*\nLocation: \Q$target/,
#	"test rule -- rule-based target redirect";

# Pseudo-location: http://escholarship.org/uc/item/123456789
# yyy still no $blade support for escholarship because we don't
#    recognize non-standard shoulders (no first digit convention)
$x = `wegn -v locate "ark:/13030/qt123456789"`;
like $x, qr{^Location: http://escholarship.org/uc/item/123456789}m,
	"Escholarship target redirect via post-egg Apache kludge";

($i, $q) = ('ab_262044', '-z-?');
$target = 'https://scicrunch.org/resolver/RRID:$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

#print qq@wegn -v locate "RriD:$i?$q"\n@;
# xxx this test should be made to work
#$x = `wegn -v locate "RriD:$i?$q"`;
$x = `wegn -v locate "RriD:$i"`;
#like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"RRID rule -- rule-based target redirect";

# # pmid (alias for pubmed)
# ncbi    http://www.ncbi.nlm.nih.gov/pubmed/$id
# epmc    http://europepmc.org/abstract/MED/$id

($i, $q) = ('16333295', '-z-?');
$target = 'http://www.ncbi.nlm.nih.gov/pubmed/$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

$x = `wegn -v locate "pmid:$i?$q"`;
#like $x, qr/response.*302 .*\nLocation: \Q$target/,
like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
	"PMID rule -- rule-based target redirect";

($i, $q) = ('9606', '-z-?');
$target = 'http://www.rcsb.org/pdb/explore/explore.do?structureId=$id';
#$target = 'http://www.pdbe.org/$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

#$x = `wegn -v locate "pdb:$i?$q"`;
# xxx bug in query string re-attachment after prefix lookup
#     but why does pmid (above) work?
$x = `wegn -v locate "pdb:$i"`;
#like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"PDB rule -- rule-based target redirect";
#print "xxx disabled test: PDB rule -- rule-based target redirect\n";

$x = `wegn -v locate "igsn:SSH000SUA"`;
$target = 'http://hdl.handle.net/10273/SSH000SUA';
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"IGSN rule -- rule-based target redirect";

($i, $q) = ('9606', '-z-?');
$target = 'http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

#$x = `wegn -v locate "taxonomy:$i?$q"`;
$x = `wegn -v locate "taxonomy:$i"`;
# xxx bug in query string re-attachment after prefix lookup
#     but why does pmid (above) work?
#like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"TAXONOMY rule -- rule-based target redirect";
#print "xxx disabled test: TAXONOMY rule -- rule-based target redirect\n";

($i, $q) = ('6622', '-z-?');
$target = 'http://www.ncbi.nlm.nih.gov/gene/$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

($i, $q) = ('0006915', '-z-?');
$target = 'http://amigo.geneontology.org/amigo/term/GO:$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

$x = `wegn -v locate "amigo/go:$i"`;
#like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"prefix (amigo/go) with provider code -- rule-based target redirect";

$i = '16333295';
$target = 'http://www.ncbi.nlm.nih.gov/pubmed/16333295';
$x = `wegn -v locate "ncbi/pmid:$i"`;
like $x, qr/response.*302 .*\nLocation: \Q$target/,
    "prefix (ncbi/pmid) with provider code and alias -- rule-based redirect";

#intenz  http://www.ebi.ac.uk/intenz/query?cmd=SearchEC&amp;ec=$id
#expasy  http://enzyme.expasy.org/EC/$id
($i, $q) = ('1.1.1.1', '-z-?');
$target = 'http://www.ebi.ac.uk/intenz/query?cmd=SearchEC&ec=$id';
$i = uc $i;
$target =~ s/\$id\b/$i/g;

$x = `wegn -v locate "ec:$i"`;
#like $x, qr/response.*302 .*\nLocation: \Q$target?$q/,
like $x, qr/response.*302 .*\nLocation: \Q$target/,
	"EC -- rule-based target redirect";
#print "xxx disabled test: EC -- rule-based target redirect\n";

$x = `wegn -v locate "ark:/99166/w6foo"`;
like $x, qr/response.*303 .*\nLocation: http:..\Q$snachost/,
	"SNAC target redirect with 303 status";

$x = `wegn locate "e/naan_request"`;
like $x, qr|Location: .*goo.gl/forms|,
	"NAAN request form is available";

$x = `wegn resolve "e/cdl_ebi_prefixes.yaml"`;
like $x, qr|- namespace: pubmed|, "prefix registry file is available";

#RewriteRule ^/e/prefix_request(\.|\.html?)?\$ https://docs.google.com/forms/d/18MBLnItDYFOglVNbhNkISqHwB-pE1gN1YAqaARY9hDg [L]
$x = `wegn -v locate "e/prefix_request"`;
like $x, qr|response.*302 .*\nLocation: .*docs.google.com/forms/d/18MBLnItDYF|,
	"special redirect to prefix request form";

#RewriteRule ^/e/prefix_overview(\.|\.html?)?\$ https://docs.google.com/document/d/1qwvcEfzZ6GpaB6Fql6SQ30Mt9SVKN_MytaWoKdmqCBI [L]
$x = `wegn -v locate "e/prefix_overview"`;
like $x, qr|response.*302 .*\nLocation: .*docs.google.com/document|,
	"special redirect to prefix overview document";

$x = `wegn loc\@xref\@\@xref $eoi.set _t $eoi_tgt`;
like $x, qr/^egg-status: 0/m,
	"egg sets target URL in CrossRef binder for EOI/DOI $eoi";

$x = `wegn loc\@xref\@\@xref $eoi.fetch _t`;
like $x, qr/^_t: \Q$eoi_tgt/m, "new bound EOI target value fetched";

$x = `wegn locate "$eoi_ref"`;
like $x, qr/^Location: \Q$eoi_tgt/m, "bound EOI target value resolved";

## XXX remove this test when xref corrects this: single _ instead of double __
#$x = `wegn loc\@xref\@xref $eoi.set _mTm. $eoi_tgt/xxxmdata`;
#$x = `wegn loc\@xref\@xref $eoi.fetch _mTm.`;
#like $x, qr|^_mTm.: \Q$eoi_tgt/xxxmdata|m,
#	"xxx bound EOI default content negotiation (CN) target value fetched";

## XXX remove this test when xref corrects this: single _ instead of double __
#$x = `wegn -v --header=Accept:text/turtle locate "$eoi_ref"`;
#like $x, qr|^Location: \Q$eoi_tgt/xxxmdata|m,
#	"xxx default EOI CN target resolution triggered by Accept header";

my $rp = File::Binder::RSRVD_PFIX;

#$x = `wegn loc\@xref\@xref $eoi.set __mTm. $eoi_tgt/mdata`;
#$x = `wegn loc\@xref\@xref $eoi.fetch __mTm.`;
$x = `wegn loc\@xref\@\@xref $eoi.set ${rp}Tm. $eoi_tgt/mdata`;
$x = `wegn loc\@xref\@\@xref $eoi.fetch ${rp}Tm.`;
like $x, qr|^${rp}Tm.: \Q$eoi_tgt/mdata|m,
	"new bound EOI default content negotiation (CN) target value fetched";

# xxx wegn --header=... must have no whitespace in it
$x = `wegn -v --header=Accept:text/turtle locate "$eoi_ref"`;
like $x, qr|^Location: \Q$eoi_tgt/mdata|m,
	"default EOI CN target resolution triggered by Accept header";

$x = `wegn locate "$eoi_ref_lc"`;
like $x, qr/^Location: \Q$eoi_tgt/m,
	"bound EOI target value resolved, even with lowercase reference";

# xxx re-instate the purge for tidiness?
#$x = `wegn loc\@xref\@xref $eoi.purge`;
#like $x, qr/^egg-status: 0/m,
#	"purge test id $eoi from CrossRef binder";

# yyy Selected redirects until the naanders database is in place (temporary) 
#
$x = `wegn locate ark:/12148/foo`;
like $x, qr|^Location: http://ark\.bnf\.fr/.*foo|m, "BNF redirect";
#
$x = `wegn locate ark:/67531/foo`;
like $x, qr|^Location: http://digital\.library\.unt\.edu/.*foo|m,
	"UNT redirect";
#
$x = `wegn locate ark:/76951/foo`;
like $x, qr|^Location: http://ark\.spmcpapers\.com/.*foo|m, "SPMC redirect";

exit;

# XXX bug: https://n2t.net/ark:/99999/fk8testn2t gets Forbidden
# XXX bug: https://localhost:18443/ark:/99999/fk8testn2t gets Location http://jak-macbook.local:18880/e/api_help.html

#===
my $arkOCA = "ark:/13960/xt897";
my $tgtOCA = "http://foo.example.com/target4";

#my ($usr, $bdr) = ('oca', 'oca_test');
my ($usr, $bdr) = ('oca', 'oca_test');

$x = `wegn \@$usr\@$bdr $arkOCA.set _t $tgtOCA`;
$x = `wegn \@$usr\@$bdr $arkOCA.get _t`;
#$x = run_cmdz_in_body($td, $usr, $bdr, $cmdblock);
like $x, qr{_t: $tgtOCA}si,
	"set $bdr:$arkOCA to $tgtOCA";

$x = `wegn "t-$arkOCA"`;
like $x, qr{HTTP/\S+\s+302\s.*Location:\s*$tgtOCA}si,
	"OCA NAAN sent to OCA binder";
#===

}


