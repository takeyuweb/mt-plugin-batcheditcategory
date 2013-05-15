package BatchEditCategory::Plugin;

use strict;

sub _cb_tp_edit_entry_batch {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q = $app->param;
    return unless $q->param( '_type' ) eq 'entry';
    
    $param->{ html_head } ||= '';
    $param->{ html_head } .= <<"TMPL";
<link href="@{[ $app->static_path ]}plugins/BatchEditCategory/styles.css" rel="stylesheet"/>
<link href="@{[ $app->static_path ]}plugins/BatchEditCategory/vendor/select2/select2.css" rel="stylesheet"/>
TMPL

    $param->{ js_include } ||= '';
    $param->{ js_include } .= <<"TMPL";
<script type="text/javascript" src="@{[ $app->static_path ]}plugins/BatchEditCategory/vendor/select2/select2.js"></script>
<script type="text/javascript" src="@{[ $app->static_path ]}plugins/BatchEditCategory/plugin.js"></script>
TMPL


    foreach my $row ( @{ $param->{ object_loop } } ) {
        my $entry_id = $row->{ id };
        my $entry = ( $entry_id ? MT->model( 'entry' )->load( $entry_id ) : undef ) or next;
        foreach my $this_c_data ( $row->{ row_category_loop } ) {
            foreach my $c ( @$this_c_data ) {
                my $cat_id = $c->{ category_id };
                my $cat = ( $cat_id ? MT->model( 'category' )->load( $c->{ category_id } ) : undef ) or next;
                if ( $entry->category && $entry->category->id == $cat->id ) {
                    $c->{ _is_primary } = 1;
                }
                if ( $entry->is_in_category( $cat ) ) {
                    $c->{ _is_selected } = 1;
                }
            }
        }
    }
}

sub _cb_ts_edit_entry_batch {
    my ( $cb, $app, $tmpl_ref ) = @_;
    my $q = $app->param;
    return unless $q->param( '_type' ) eq 'entry';
    my $field_tmpl = <<'TMPL';
        <select multiple>
            <option value=""><__trans phrase="None"></option>
            <mt:loop name="row_category_loop">
                <option value="<$mt:var name="category_id"$>" title="<$mt:var name="category_label" encode_html="1"$>"<mt:if name="_is_selected"> selected="selected"</mt:if><mt:if name="_is_primary"> data-primary="1"</mt:if>><$mt:var name="category_label_spacer"$><$mt:var name="category_label" encode_html="1"$></option>
            </mt:loop>
        </select>
        <input type="hidden" name="category_id_<$mt:var name='id'$>" class="category_id" />
        <input type="hidden" name="category_ids_<$mt:var name='id'$>" class="category_ids" />
TMPL
    $$tmpl_ref =~ s|<select name="category_id_(?:.+?)</select>|$field_tmpl|s;
    
    $$tmpl_ref = $$tmpl_ref . <<'TMPL';
<mt:setvarblock name="jq_js_include" append="1">
</mt:setvarblock>
TMPL
}

sub _cb_post_bulk_save_entries {
    my ( $cb, $app, $ref_entries ) = @_;
    my $q = $app;
    foreach my $pair ( @$ref_entries ) {
        my $entry = $pair->{ current };
        my $orig = $pair->{ original };
        my $entry_id = $entry->id;
        my $blog_id = $entry->blog_id;
        my $ids_str = $q->param("category_ids_$entry_id");
        next unless defined $ids_str;
        
        my @placements = MT->model( 'placement' )->load(
            {   entry_id   => $entry_id,
                is_primary => 0
            }
        );
        foreach my $placement ( @placements ) {
            $placement->remove or die $placement->errstr;
        }
        
        my @cat_ids = do{  my %wk; grep { !$wk{$_}++ } split( ',', $ids_str ) };
        @cat_ids = grep { $_ } @cat_ids;
        next unless @cat_ids;
        foreach my $cat_id ( @cat_ids ) {
            my $placement = MT->model( 'placement' )->new;
            $placement->entry_id( $entry_id );
            $placement->blog_id( $blog_id );
            $placement->is_primary(0);
            $placement->category_id( $cat_id );
            $placement->save or die$placement->errstr;
        }
    }
    1;
}

1;
