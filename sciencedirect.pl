#!/usr/bin/perl -s
#
# This script uses Mechanize to download papers from a ScienceDirect journal page.
#
# TODO add check_for_volume() function; 
#
#
# Usage:
#
#   perl sciencedirect.pl [journal url] [volume] [issue]
#
# The URL argument is required, but the volume and issue arguments are optional.
#
#
# Example: download journal/volume/issue
#
#   perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/15407489' 30 1
#
#
# Example: download journal/volume
#
#   perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/15407489' 30 
#
#
# Example: download journal
#
#   perl sciencedirect.pl 'http://www.sciencedirect.com/science/journal/15407489'
#
#
# How it works:
#
# - You specify a journal url, and (optionally) a volume/issue number.
# - The script initializes a Schwartz-Mechanizer object.
# - The script determines if you want to download a whole journal, a whole volume, or a whole issue.
# - If you specify a whole journal, it starts from the latest volume and iterates backwards through each volume number.
# - If you specify a whole volume, it starts from the latest issue and iterates backwards through each issue number.
# - For each issue, the script assembles an array of links to articles listed on the page.
# - The script then loops through the array and downloads the articles to PDF files.
# - The script repeats this for each issue of each volume.

use strict;
use WWW::Mechanize;
use HTML::TokeParser;
use HTTP::Cookies::Mozilla;
use HTML::Entities;



####################################################
# do it
####################################################

if( $#ARGV == -1 ) {
    print "\n********* ERROR! *********\n\n";
    print " Usage:\n\n";
    print "   perl sciencedirect.pl [journal url] [volume] [issue] \n\n";
    die "The journal URL argument is required, but you did not provide one.\n"
}

my $journalURL;
my $volumeNumber;
my $issueNumber;
my $journalName;

# process user arguments:
# ----------------------
$journalURL   = $ARGV[0];
$volumeNumber = $ARGV[1];
$issueNumber  = $ARGV[2];

# initialize the science direct swartz-mechanizer:
# ------------------------------
# create a cookie jar
my $cookie_jar = HTTP::Cookies::Mozilla->new( ignore_discard => 1);

# create a mechanizer
my $mech = WWW::Mechanize->new( cookie_jar => $cookie_jar );

$mech->get($journalURL);
$mech->get($journalURL);
$_ = $mech->content;

# you are now on the page with all the articles listed.

# determine what to do with the arguments.
# --------------------------
if( defined $issueNumber ) {
    # if user provided an issue, they want to download that entire issue.
    # if user provided a url, they want to download all/only papers at that URL.
    downloadSpecifiedVolumeIssue($mech,$journalURL,$volumeNumber,$issueNumber);

} elsif ( defined $volumeNumber ) {
    # -----------------
    # (this doesn't work right now)
    # if user provided a volume, they want to download that entire volume
    downloadSpecifiedVolume($mech,$journalURL,$volumeNumber);
    # -----------------

} elsif( defined $journalURL ) {
    # -----------------
    # (this doesn't work right now)
    # if user provided a volume, they want to download that entire journal
    downloadSpecifiedJournal($mech,$journalURL);
    # -----------------

}

print "All done!\n";



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
    my $journal_issue2_; # << if necessary
    my $journal_yr_;

    if( $title =~ /(.*) \| Vol ([0-9]{1,}), Iss ([0-9]{1,}), Pgs .* \(.*([0-9]{4})\) \| ScienceDirect\.com/ ) {
        # if journal is volume & issue (normal)
        $journal_name_  = $1;
        $journal_vol_   = $2;
        $journal_issue_ = $3;
        $journal_yr_    = $4;

    } elsif( $title =~ /(.*) \| Vol ([0-9]{1,}), Isss ([0-9]{1,}).*([0-9]{1,}), Pgs .*\(.*([0-9]{4})\) \| ScienceDirect\.com/ ) {
        # if journal is volume & issues (multiple issues per single page)
        $journal_name_   = $1;
        $journal_vol_    = $2;
        $journal_issue_  = $3;
        $journal_issue2_ = $4;
        $journal_yr_     = $5;

        # multiple issue numbers; set it to first issue number, 
        # otherwise it will treat the issue number as invalid
        # and will default to the latest volume/issue of the journal

    } elsif( $title =~ /(.*) \| Vol ([0-9]{1,}), Pgs .*\(.*([0-9]{4})\) \| ScienceDirect\.com/ ) {
        # if journal is volume-only (no issue) 
        # e.g. Energy Economics http://www.sciencedirect.com/science/journal/01409883
        $journal_name_  = $1;
        $journal_vol_   = $2;
        $journal_yr_    = $4;

        # no issue number, so just set it = to 1 
        # (specifying any issue number will make it default to the latest volume/issue,
        #  and only the latest volume/issue will be listed as "in progress" anyway) 
        $journal_issue_ = 1;

    } elsif( $title =~ /(.*) \| Vol ([0-9]{1,}), Iss ([0-9]{1,}),  In Progress , .*\(.*([0-9]{4})\) \| ScienceDirect\.com/ ) {
        # if journal is in progress, and volume & issue
        $journal_name_  = $1;
        $journal_vol_   = $2;
        $journal_issue_ = $3;
        $journal_yr_    = $4;

    } elsif( $title =~ /(.*) \| Vol ([0-9]{1,}),  In Progress , .*\(.*([0-9]{4})\) \| ScienceDirect\.com/ ) {
        # if journal is in progress, and volume-only (no issue)
        $journal_name_  = $1;
        $journal_vol_   = $2;
        $journal_yr_    = $3;

        # no issue number, so just set it = to 1 
        $journal_issue_ = 1;

    } else {
        print "Error from page " . $get_journal_info_mech_->uri() . "\n";
        print "Malformed title. Check if the title is in one of the following forms: \n\n";
        print "    <title>[Journal Name] | Vol [#], Iss [#], Pgs [#], ([Year]) | ScienceDirect.com</title>          \n";
        print "    <title>[Journal Name] | Vol [#], Isss [#-#], Pgs [#], ([Year]) | ScienceDirect.com</title>       \n";
        print "    <title>[Journal Name] | Vol [#], Pgs [#], ([Year]) | ScienceDirect.com</title>                   \n";
        print "    <title>[Journal Name] | Vol [#], Iss [#],  In Progress , ([Year]) | ScienceDirect.com</title>    \n";
        print "    <title>[Journal Name] | Vol [#],  In Progress , ([Year]) | ScienceDirect.com</title>             \n";
        print "\n";
        die "If your title does not match one of these formats, you will need to modify the get_journal_info() function.\n";
    }

    my @vol_info_ = ($journal_name_,$journal_vol_,$journal_issue_,$journal_yr_);
    return @vol_info_;

}



####################################################
# download everything from specified volume and issue
####################################################
# downloadSpecifiedVolumeIssue( $mech, $journalURL, $journalVolume, $journalIssue )
sub downloadSpecifiedVolumeIssue {

=pod
    init: 
        go to the URL for this volume/issue combination
        get journal name/volume/issue information
        check if this journal volume/issue has already been downloaded
    do 
        get list of all papers in a given issue
        assemble links to each paper and put them in an array
        download each link
    while
        next page button click returns true (pass it the mech object)
=cut

    my $mech_          = @_[0];
    my $journal_url_   = @_[1];
    my $journal_vol_   = @_[2];
    my $journal_issue_ = @_[3];

    # re-form the URL to point to the right volume and issue number
    my $full_journal_url_ = $journal_url_ . "/" . $journal_vol_ . "/" . $journal_issue_;

    $mech_->get($full_journal_url_);
    $mech_->get($full_journal_url_);
    $_ = $mech_->content;

    # get journal info.
    my @vol_info = get_journal_info( $mech_ );
    my $got_journal_name  = $vol_info[0];
    my $got_journal_vol   = $vol_info[1];
    my $got_journal_issue = $vol_info[2];
    my $got_journal_yr    = $vol_info[3];
    my $pretty_name = $got_journal_name . " Volume " . $got_journal_vol . " Issue " . $got_journal_issue;

    # check if volume has already been downloaded
    if( undef ) {
    #if( check_for_volume( $pretty_name ) ) # skip the check for now...
        print "This volume/issue combination has already been downloaded: ";
        print $pretty_name;
        print "\n";

    } else {

        print "\n------------------------------------\n";
        print "Downloading " . $pretty_name . "...\n";

        # do loop: process listed journal articles while next page button click returns true
        do {
            # create HTML token parser for this page
            my $div_stream  = HTML::TokeParser->new( \$mech_->content );
            my $table_stream = HTML::TokeParser->new( \$mech_->content );

            # ----------------
            # find each <div class="sectionH1 heading1"> to grab name of each papers category:
            my @div_header_tags;# list of the <div> tags
            my @paper_ids;      # paper IDs
            my @paper_names;    # list of paper names
            my @paper_links;    # list of paper links
            my @paper_authors;  # list of paper authors

            # first, grab the table of class resultsRow 
            while( my $table_tag = $table_stream->get_tag("table") ) {
                if( $table_tag->[1]{class} and $table_tag->[1]{class} eq "resultRow" ) {

                    # the first column contains a table (checkbox and paper ID #)
                    $table_stream->get_tag("td");
                        # ----------
                        $table_stream->get_tag("table");
                        $table_stream->get_tag("td");
                        my $paper_id = $table_stream->get_trimmed_text("/td");
                        $table_stream->get_tag("/table");
                        push( @paper_ids, sprintf("%03d",$paper_id) );
                        # ----------

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
                        # ----------
            
                        # ------------
                        # grab link (preview link)
                        $table_stream->get_tag("a");
                        # ----------
            
                        # ------------
                        # grab link to PDF and store/save
                        $a_tag = $table_stream->get_tag("a");
                        push( @paper_links, $a_tag->[1]{href} );
                        # ----------
            
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

        } while ( click_next_page_button($mech_) );

        print "Done downloading papers from " . $pretty_name . "\n";

        # Append that this volume/issue was saved
        print "Putting \"" . $pretty_name . "\" in the archive.\n";
        #my $file_ = $fullpath . '/archive.txt';
        my $file_ = 'archive.txt';
        open(ARCHIVE, '>>', $file_) or die "Error opening file " . $file_ . " for writing.\n";
        print ARCHIVE $pretty_name . "\n"; 
        close ARCHIVE;

        print "------------------------------------\n\n";

    }
}



####################################################
# download everything from specified volume
####################################################
# downloadSpecifiedVolume( $mechanizer, $journalURL, $journalVolume )
sub downloadSpecifiedVolume {

=pod
    init: 
        go to the journal/volume url
        get the latest issue number
    for each issue (decrement)
        downloadSpecifiedVolumeIssue 
=cut

    my $mech_          = @_[0];
    my $journal_url_   = @_[1];
    my $journal_vol_   = @_[2];



    # first, get info on the latest journal volume number. 
    # this is going to be used to see if the issue number is valid.
    # (if issue number is invalid, it redirects you to the latest volume/issue)
    $mech_->get($journal_url_);
    $mech_->get($journal_url_);
    $_ = $mech_->content;

    # get journal info.
    my @vol_info = get_journal_info( $mech_ );
    my $latest_journal_vol   = $vol_info[1]; 



    # okay, now get the user-specified volume number.
    # re-form the URL to point to the right volume 
    my $full_journal_url_ = $journal_url_ . "/" . $journal_vol_;

    $mech_->get($full_journal_url_);
    $mech_->get($full_journal_url_);
    $_ = $mech_->content;

    # get journal info.
    # if user-specified volume is different from volume retrieved by get_journal_info(),
    # the user has specified an invalid/non-existent volume.
    my @vol_info = get_journal_info( $mech_ );
    my $got_journal_name  = $vol_info[0];
    my $got_journal_vol   = $vol_info[1];
    my $got_journal_issue = $vol_info[2];
    if( $got_journal_vol != $journal_vol_ ) {
        print "WARNING: Journal " . $got_journal_name . " does not seem to have a volume " . $journal_vol_ . ". Downloading volume " . $got_journal_vol . " instead.\n";
    }

    # if we're downloading the latest volume, just download each issue without checking to see if the issue number is valid.
    # if there's a multi-issue cluster (like, Isss X-Y) in the latest volume, well, don't worry. it'll work out.
    my $is_this_latest_volume = 0;
    if( $got_journal_vol == $latest_journal_vol ) {
        $is_this_latest_volume = 1;
    }

    for( my $i = $got_journal_issue; $i > 0; $i-- ) {

        ISSUESLOOP: {
            # check if this issue number exists:
            # if an issue number is non-existent/invalid, 
            # sciencedirect will redirect you to the latest volume.
            # if it is a multi-issue listing (e.g. issues 1-2),
            # only the first issue in the series (e.g. issue 1) is valid.
            # if we get an invalid issue number, keep going.
            $mech_->get($journal_url_ . "/" . $got_journal_vol . "/" . $i);
            $mech_->get($journal_url_ . "/" . $got_journal_vol . "/" . $i);
            my @vol_info = get_journal_info( $mech_ );
            my $this_journal_vol = $vol_info[1];

            if( $is_this_latest_volume == 0 && $this_journal_vol == $latest_journal_vol ) {
                # this is a non-existent/invalid issue number
                print "Oops! Non-existent or invalid issue number: Volume " . $got_journal_vol . " Issue " . $i . " (ScienceDirect returned Volume " . $this_journal_vol . "). Continuing...\n";
                last ISSUESLOOP;
            }

            downloadSpecifiedVolumeIssue( $mech_, $journal_url_, $got_journal_vol, $i ) 
        }

    }

}



####################################################
# download everything from specified volume and issue
####################################################
# downloadSpecifiedJournal( $mechanizer, $journalURL ) 
sub downloadSpecifiedJournal {

=pod
    init: 
        go to the journal url
        get the latest volume number 
    for each volume (decrement)
        downloadSpecifiedVolume
=cut

    my $mech_        = @_[0];
    my $journal_url_ = @_[1];

    $mech_->get($journal_url_);
    $mech_->get($journal_url_);
    $_ = $mech_->content;

    # get journal info.
    my @vol_info = get_journal_info( $mech_ );
    my $latest_journal_vol   = $vol_info[1]; 

    VOLUMELOOP: {
        for( my $v = $latest_journal_vol, my $first_loop = 1; $v > 0; $v-- ) {

            # check if this volume number exists:
            # if a volume number is non-existent/invalid, 
            # sciencedirect will redirect you to the latest volume 
            $mech_->get($journal_url_ . "/" . $v);
            $mech_->get($journal_url_ . "/" . $v);
            my @vol_info = get_journal_info( $mech_ );
            my $this_journal_vol = $vol_info[1]; 

            if( $first_loop == 0 && $this_journal_vol == $latest_journal_vol ) {
                # this is a non-existent/invalid volume number
                print "Oops! Non-existent or invalid volume number: Volume " . $v . " (ScienceDirect returned Volume " . $this_journal_vol . "). Continuing... \n";
                last VOLUMELOOP;
            }

            downloadSpecifiedVolume( $mech_, $journal_url_, $this_journal_vol );

            $first_loop = 0;
        }
    }
}



####################################################
# click next page button
####################################################
# returns true if the next page button is there and is clicked
# $buttonClicked = click_next_page_button( $mech )
sub click_next_page_button() {
    my $next_page_mech_ = $_[0];
    my $next_page_uri_ = $next_page_mech_->uri();

    my $next_page_stream  = HTML::TokeParser->new( \$next_page_mech_->content );

    my $buttonClicked;

    # first, grab the link with title "Next page" table of class resultsRow 
    my $count = 0;
    while( my $next_page_tag = $next_page_stream->get_tag("a") ) {
        if( $next_page_tag->[1]{title} and $next_page_tag->[1]{title} eq "Next page" ) {
            # for some reason, the top "Next >" link won't work,
            # so use the bottom one instead.
            if( $count == 0 ) {
                $count++;
            } else {
                $next_page_mech_->get( $next_page_tag->[1]{href} );
                $buttonClicked = 'true';
            }
        }
    }

    return $buttonClicked;
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
# open_links( $mechanizer_object, $number_of_papers, $array_of_paper_links, $array_of_paper_names, $array_of_paper_ids )
sub open_links
{
    # Set the verbosity level:
    # 0 = SHUT UP
    # 1 = quiet, print paper ID number
    # 2 = loud, print full paper title
    # 3 = yell, print full paper title and save destination file
    my $verbosity_level = 2;

    # Setting fake save switch makes the script pretend to download the papers but doesn't actually (for debugging)
    # 0 = actually save papers to disk
    # 1 = fake-save papers 
    my $fake_save = 0; 

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
    my $journal_yr    = $vol_info[3];

    #####################################

    # Check for this volume in the list of archived journal vols
    my $volissue_string = $journal_name . " Volume " . $journal_vol . " Issue " . $journal_issue;
    if( undef ) {
    #if( check_for_volume( $journal_name, $journal_vol, $journal_issue ) ) 
        print "This volume/issue combination has already been downloaded: ";
        print $volissue_string;
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
            my $export_file = $journal_name . " v" . $journal_vol . " i" . $journal_issue . " " . $paper_ids_[$i] . ".pdf";

            if( $verbosity_level == 0 ) {
            } elsif ( $verbosity_level == 1 ) {
                print "Saving paper " . $paper_ids_[$i] . " from " . $export_file . "... ";
            } elsif ( $verbosity_level == 2 ) {
                print "Saving paper \"" . Encode::encode_utf8( $paper_names_[$i] ) . "\"... ";
            } elsif ( $verbosity_level == 3 ) {
                print "Saving paper \"" . Encode::encode_utf8( $paper_names_[$i] ) . "\" to file \"" . $export_file . "\"... ";
            }

            # save link target to file 
            if( $fake_save == 0 ) {
                # :content_file is used to save the results of a get request to a file 
                # http://lwp.interglacial.com/ch03_04.htm
                $open_links_mech_->get( $paper_links_[$i], ':content_file' => $fullpath . '/' . $export_file );
            }

            print "Done.\n";
        }

        # this is REQUIRED, otherwise the last get() with a paper link
        # messes up the Mech object...
        $open_links_mech_->get( $open_links_uri_ );

    }

    #####################################

}



=pod
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
=cut

