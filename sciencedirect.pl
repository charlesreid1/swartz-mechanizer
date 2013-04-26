#!/usr/bin/perl -w
use strict;

use WWW::Mechanize;
use HTML::TokeParser;
use HTTP::Cookies::Mozilla;
use HTML::Entities;

# create a cookie jar
my $cookie_jar = HTTP::Cookies::Mozilla->new( ignore_discard => 1);

# create a mechanizer
my $mech = WWW::Mechanize->new( cookie_jar => $cookie_jar );

# Proceedings of the Combustion Institute
$mech->get('http://www.sciencedirect.com/science/journal/15407489');
$mech->get('http://www.sciencedirect.com/science/journal/15407489');

## Acta Mathematica Scientia
#$mech->get('http://www.sciencedirect.com/science/journal/02529602');
#$mech->get('http://www.sciencedirect.com/science/journal/02529602');

## Combustion & Flame
#$mech->get('http://www.sciencedirect.com/science/journal/00102180');
#$mech->get('http://www.sciencedirect.com/science/journal/00102180');
$_ = $mech->content;

# you are now on the page with all the articles listed


=pod

switch  --> switch_vol-iss
switch2 --> switch_page

Get page (done above)
    while( switch == true )
    {
        while( switch2 == true )
        {
            get all papers from page
            look for next> page button
            if found, switch2 = true
            else switch2 = false
        }
        look for previous vol/iss< button
        if found switch = true
        else switch = false
    }
=cut

my $switch_vol_iss = 1;
my $switch_page = 1;

while( $switch_vol_iss == 1 )
{
    while( $switch_page == 1 )
    {
        process_listed_journal_articles( $mech );
        $switch_page = look_for_next_page_button( $mech );
    }
    $switch_page = 1;
    
    $switch_vol_iss = look_for_prev_vol_button( $mech );
}
















# Look for (& click) Next> next page button
# 
# look_for_next_page_button( $mech_ )
sub look_for_next_page_button
{
    # for the Next page:
    #<a class="ActionButton" onclick="javascript:submitTocList('next'); return false"
    #   href="..." title="Next page" alt="Next page">Next *</a>

    my $mech_ = $_[0];

    my $stream_next_page = HTML::TokeParser->new( \$mech_->content );

    while( my $a_tag = $stream_next_page->get_tag("a") )
    {
        if( $a_tag->[1]{class} and 
            $a_tag->[1]{class} eq "ActionButton" and 
            $a_tag->[1]{title} eq "Next page" )
        {
            # this is the Next Page link, so get it
            #print"\tGet()ting the link for the next page.\n";
            $mech_->get($a_tag->[1]{href});
            $_[0] = $mech_;
            return 1;
        }
    }

    return 0;
}


# Look for (& click) "Previous volume" button
#
# look_for_prev_vol_button( $mech_ )
sub look_for_prev_vol_button
{
    # for the Previous Volume button: 
    #<a class="ActionButton" 
    #   href="..." title="Previous volume/issue">
    #   &lt; Previous vol/iss</a>

    my $mech_ = $_[0];
    my $stream_next_page  = HTML::TokeParser->new( \$mech_->content );

    while( my $a_tag = $stream_next_page->get_tag("a") )
    {
        if( $a_tag->[1]{class} and 
            $a_tag->[1]{class} eq "ActionButton" and 
            $a_tag->[1]{title} =~ /Previous volume/ )
        {                                                                                                      
            # this is the Previous Volume link, so get it
            #print"\tGet()ting the link for the previous volume:" . $a_tag->[1]{href} . "\n";
            $mech_->get($a_tag->[1]{href}); 
            $_[0] = $mech_;
            return 1;                                                                                       
        }                                                                                                      
    }                                                                                                          

    return 0;
                                                                                                               
}                                                                                                              




# Process list of journal articles
# 
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


# Open links:
# 
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

        # this is REQUIRED, otherwise the last get() with a paper link messes up the Mech object...
        $open_links_mech_->get( $open_links_uri_ );

    }

    # -----------------------------------
}



# Get journal information
#
# This returns the following information, in the following order:
# - journal name
# - journal volume
# - journal issue
# - journal pages
# - journal year
# 
# @vol_info = get_journal_info( const $mech_ )
sub get_journal_info
{
    # Store information about this volume+issue from the title
    my $get_journal_info_mech_ = $_[0];
    
    # grab the title: "ScienceDirect - [Journal Name], Volume [Vol #], Issue [Issue #], Pages [Page #s] ([Month] [Yr])
    # grab the title: "[Journal Name], Vol [Vol#], Iss [Issue#], Pgs [#]-[#], [Month], [Yr] | ScienceDirect.com"
    my $title_stream  = HTML::TokeParser->new( \$get_journal_info_mech_->content );
    $title_stream->get_tag("title");
    my $title = $title_stream->get_text("/title");

    my $journal_name_ ; 
    my $journal_vol_;  
    my $journal_issue_; 
    my $journal_pages_; 
    my $journal_yr_;

    if( $title =~ /(.*) \| Vol (.*), Iss (.*), Pgs (.*), .*\(.*([0-9]{4})\) \| ScienceDirect\.com/ )
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




# Check for volume
# 
# This checks to see if a given volume and issue of a journal
# has already been downloaded.
# 
# Returns true if the volume is contained in the archive list.
# Returns false if the volume is not contained in the archive list.
#
# check_for_volume( const $journal_name, 
#                   const $journal_vol, 
#                   const $journal_issue )
sub check_for_volume
{
    my $journal_name_  = $_[0];
    my $journal_vol_   = $_[1];
    my $journal_issue_ = $_[2];

    # first construct the "key"
    my $key_ = $journal_name_ . " Volume " . $journal_vol_ . " Issue " . $journal_issue_;
    my $file_ = 'archive.txt';

    # Open file for reading
    #unless( -e "archive.txt" )
    #{
    #    open FILEHANDLE, "+>archive.txt";
    #    print FILEHANDLE " \n";
    #    close FILEHANDLE;
    #    #die "Error opening file " . $file . " for reading: file does not exist.\n";
    #}
    open(ARCHIVE,"+>archive.txt") or die "Error opening file " . $file_ . " for reading.\n";

    DUPECHECK: {
        my $line;
        while( <ARCHIVE> )
        {
            # store the $_ value
            $line = $_;

            # get rid of trailing \n char
            chomp($line);

            if( $line eq $key_ )
            {
                return 1;
                last DUPECHECK;
            }
        }
        return 0;
    }

    close ARCHIVE;
}





