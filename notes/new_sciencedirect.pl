#!/usr/bin/perl -w -s
#
# This script uses Mechanize to download papers from a ScienceDirect journal page.
# 
# Example usage:
# 
# Download an entire issue of a journal:
#   perl sciencedirect.pl -journal="Cell" -vol="100" -issue="27"
#
# Download an entire volume of a journal:
#   perl sciencedirect.pl -journal="Proceedings of the Combustion Institute" -vol="30"
#
# Download an entire journal:
#   perl sciencedirect.pl -journal="Acta Mathematica" 
#
# Download all papers from a specific journal URL:
#   perl sciencedirect.pl -journalurl='http://www.sciencedirect.com/science/journal/15407489'
# 
# How it works:
#
# You specify a journal, and (optionally) a volume/issue number.
# The script initializes a Schwartz-Mechanizer object.
# Then the script then determines if you want to download a whole journal, a whole volume, or a whole issue.
# Then the script does that.

use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use HTTP::Cookies::Mozilla;
use HTML::Entities;



####################################################
# okay, let's do it
####################################################

# initialize the science direct schwartz-mechanizer:
# ------------------------------
my $cookie_jar;
my $mech;

# create a cookie jar
$cookie_jar = HTTP::Cookies::Mozilla->new( ignore_discard => 1);

# create a mechanizer
$mech = WWW::Mechanize->new( cookie_jar => $cookie_jar );

# process user arguments:
# ----------------------

# -journal="Proceedings of the Combustion Institute" 
# -vol=30 
# -issue=25
# -journalurl

# establish a starting point
# if user has not specified a URL, go to the journal's main page
if( $journalurl ) {
    $mech->get( $journalurl );
} else {
    get_journal_url($mech, $journal)
}

# determine what to do with the arguments.
# --------------------------
if ($issue || $journalurl) {
    # if user provided an issue, they want to download that entire issue.
    # if user provided a url, they want to download all/only papers at that URL.
    downloadSpecifiedVolumeIssue($journal,$vol,$issue)
} else
if ($volume) {
    # if user provided a volume, they want to download that entire volume
    downloadSpecifiedVolume($journal,$vol)
} else 
if($journal) {
    # if user provided a volume, they want to download that entire journal
    downloadSpecifiedJournal($journal)
}



####################################################
# get the url for the main page of a journal 
# (given its name)
####################################################
# get_journal_url($mechanizeObject)
sub get_journal_url {
    # go to the science direct website
    # perform a search with the $journal name
    # return the URL for that journal's main page
    # (i.e. the latest issue)
    # (i.e. the starting point for everything)
}



####################################################
# get the title, volume, issue, etc. of a journal
# (given its name)
#
# This returns the following information, in the following order:
# - journal name
# - journal volume
# - journal issue
# - journal pages
# - journal year
####################################################
# @vol_info = get_journal_info( const $mech_ )
sub get_journal_info {
    # Store information about this volume+issue from the title
    my $get_journal_info_mech_ = $_[0];
    
    # grab the title: "ScienceDirect - [Journal Name], Volume [Vol #], Issue [Issue #], Pages [Page #s] ([Month] [Yr])
    my $title_stream  = HTML::TokeParser->new( \$get_journal_info_mech_->content );
    $title_stream->get_tag("title");
    my $title = $title_stream->get_text("/title");

    my $journal_name_ ; 
    my $journal_vol_;  
    my $journal_issue_; 
    my $journal_pages_; 
    my $journal_yr_;

    if( $title =~ /(.*) | Vol (.*), Iss (.*), Pgs (.*), ,\(.*?([12][90][0-9][0-9])\)/ )
    {
        $journal_name_  = $1;
        $journal_vol_   = $2;
        $journal_issue_ = $3;
        $journal_pages_ = $4;
        $journal_yr_    = $5;
    
        print "\n";
        print "Journal name = "   . $journal_name_  . "\n";
        print "Journal volume = " . $journal_vol_   . "\n";
        print "Journal issue = "  . $journal_issue_ . "\n";
        print "Journal pages = "  . $journal_pages_ . "\n";
        print "Journal year = "   . $journal_yr_    . "\n";
        print "\n";

    } else {
        print "Error from page " . $get_journal_info_mech_->uri() . "\n";
        die "Malformed title. Please check to make sure the title is correct.\n";
    }

    my @vol_info_ = ($journal_name_,$journal_vol_,$journal_issue_,$journal_pages_, $journal_yr_);
    return @vol_info_;

}



####################################################
# download everything from specified volume and issue
####################################################
sub downloadSpecifiedVolumeIssue {
=pod
    init: 
        get list of all papers in a given issue
        assemble links to each paper in a given issue
        create array of all papers in a given issue
        shove links into array
    do 
        process listed journal articles
        open links
    while
        next page button click returns true (pass it the mech object)
=cut
}



####################################################
# download everything from specified volume
####################################################
sub downloadSpecifiedVolume {
=pod
    init: 
        get list of all issues in a given volume
        assemble links to each issue in a given volume
        create array of all issues in a given volume
        shove links into array
    do
        downloadSpecifiedVolumeIssue 
    while
        previous issue button click returns true (pass it the mech object)
=cut
}



####################################################
# download everything from specified volume and issue
####################################################
sub downloadSpecifiedJournal {
=pod
    init: 
        get list of all volumes in a given journal
        assmelbe links to each volume in a given journal
        create array of all volumes in a given journal
        shove links into array
    do 
        downloadSpecifiedVolume
    while
        previous volume button click returns true 
=cut
}



####################################################
# process list of journal articles
####################################################
# process_listed_journal_articles( $mech )
sub process_listed_journal_articles
{
    if( $#_ != 0 )
    {
        die "Too many arguments given to process_listed_journal_articles(). Shoud be 1, was actually " . $#_+1 . "\n";
    }
    
    my $mech_ = $_[0];

    # create HTML token parser for this page
    my $div_stream  = HTML::TokeParser->new( \$mech_->content );
    my $table_stream = HTML::TokeParser->new( \$mech_->content );
    
    # ----------------
    # find each <div class="sectionH1 heading1"> to grab name of each papers category:
    
    # list of the <div> tags
    my @div_header_tags;
    
    # paper IDs
    my @paper_ids;
    
    # list of paper links
    my @paper_links;
    
    # list of paper names
    my @paper_names;
    
    # list of paper authors
    my @paper_authors;

    # first, grab the table of class resultsRow 
    while( my $table_tag = $table_stream->get_tag("table") )
    {
        if( $table_tag->[1]{class} and $table_tag->[1]{class} eq "resultRow" )
        {
            # the first column contains a table (checkbox and paper ID #)
            $table_stream->get_tag("td");
                $table_stream->get_tag("table");
                $table_stream->get_tag("td");
                my $paper_id = $table_stream->get_trimmed_text("/td");
                $table_stream->get_tag("/table");
    
                push( @paper_ids, sprintf("%03d",$paper_id) );
    
            # the second column contains the paper name/authors/link/etc
            $table_stream->get_tag("td");
    
                # ----------
                # grab link (abstract/paper link)
                my $a_tag = $table_stream->get_tag("a");
    
                # save paper name
                my $paper_name = $table_stream->get_text("/a");
                push( @paper_names, $paper_name );
    
                # save paper authors
                $table_stream->get_tag("br");
                $table_stream->get_tag("br");
                my $paper_author = $table_stream->get_text("br");
                push( @paper_authors, $paper_author );
    
                # ------------
                # grab link (preview link)
                $table_stream->get_tag("a");
    
                # ------------
                # grab link to PDF and store/save
                $a_tag = $table_stream->get_tag("a");
                push( @paper_links, $a_tag->[1]{href} );
    
            # go to the last /table tag
            $table_stream->get_tag("/table");
    
        }#end if resultrow table
    }#end table loop



    # Check that size of paper arrays are the same
    my $paper_links_size        = scalar @paper_links;
    my $paper_names_size        = scalar @paper_names;
    my $paper_authors_size      = scalar @paper_authors;
    my $paper_ids_size          = scalar @paper_ids;
    
    if( $paper_links_size != $paper_names_size ||
        $paper_links_size != $paper_authors_size ||
        $paper_links_size != $paper_ids_size )
    {
        die "Error: list size of paper links do not match list sizes of names, authors, or IDs.\n";
    }

    open_links( $mech_, $paper_links_size, @paper_links, @paper_names, @paper_ids );
}



####################################################
# open an array of links
####################################################
# open_links( $mech, $N_papers, $paper_links, $paper_names, $paper_ids )
sub open_links
{
    my $N_papers = $_[1];
    if( $#_ != (1+3*$N_papers) )
    {
        print "The number of parameters was: ";
        print $#_ + 1;
        die "Too many arguments given to open_links(). Should be 3N + 1 = " . (1+3*$N_papers) . " \n"; 
    }

    my $open_links_mech_ = $_[0];
    my $open_links_uri_ = $open_links_mech_->uri();

    my @paper_links_;
    my @paper_names_;
    my @paper_ids_;
    for( my $i=0; $i < $N_papers; $i++ )
    {
        push( @paper_links_, $_[ 2 + $i ] );
        push( @paper_names_, $_[ 2 + 1*$N_papers + $i ] );
        push( @paper_ids_  , $_[ 2 + 2*$N_papers + $i ] );
    }

    my @vol_info;
    @vol_info = get_journal_info( $open_links_mech_ );

    my $journal_name  = $vol_info[0];
    my $journal_vol   = $vol_info[1];
    my $journal_issue = $vol_info[2];
    my $journal_pages = $vol_info[3];
    my $journal_yr    = $vol_info[4];

    my $vol_string2 = $journal_name . " Volume " . $journal_vol . " Issue " . $journal_issue;

    print "\n------------------------------------\n";
    print "Title: " . $vol_string2 . "\n";

    #####################################

    # Check for this volume in the list of archived journal vols
    my $vol_string = $journal_name . " Volume " . $journal_vol . " Issue " . $journal_issue;
    if( check_for_volume( $journal_name, $journal_vol, $journal_issue ) )
    {
        print "This volume/issue combination has already been downloaded: ";
        print $vol_string;
        print "\n";

    } else {
        require Encode;

        # create directory structure - volume, issue, number
        # ---8<--- 
        #                                                                          
        # from http://alumnus.caltech.edu/~svhwan/prodScript/avoidPwdFindMkdir.html
        use Cwd;
        use File::Path;

        my $newDir = "$journal_name/Volume_$journal_vol/Issue_$journal_issue";
        my $curDir = &Cwd::cwd();

        my $fullpath = '/' . $curDir . '/' . $newDir;

        &File::Path::mkpath($fullpath);
        # ---8<---

        foreach my $i (0..$#paper_links_)
        {
            # use journal name to form filename

            ## be verbose & print full paper title
            #print "Saving paper \"" . Encode::encode_utf8( $paper_names_[$i] ) . "\" to file \"" . $export_file . "\"... ";

            # be quiet & print paper ID number
            print "Saving paper " . $paper_ids_[$i] . "... ";

            # export filename
            my $export_file = $journal_name . " " . $paper_ids_[$i] . ".pdf";
            print $export_file . "... ";

            # SAVE
            # save link target to file (WORKS!)
            $open_links_mech_->get( $paper_links_[$i], ':content_file' => $fullpath . '/' . $export_file );

            print "Done.\n";
        }

        # Append that this volume was saved
        my $file_ = $fullpath . '/archive.txt';
        open(ARCHIVE,">>$file_") or die "Error opening file " . $file_ . " for writing.\n";
        print ARCHIVE $vol_string . "\n"; 
        print "Putting " . $vol_string . " in the archive.\n";
        close ARCHIVE;

        # this is REQUIRED, otherwise the last get() with a paper link
        # messes up the Mech object...
        $open_links_mech_->get( $open_links_uri_ );

    }

    # -----------------------------------
}








