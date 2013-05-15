jQuery(function(){(function($){
    function escapeHTML(t) {
        return $('<div/>').text(t).html();
    }
    function format(state) {
        var originalOption = state.element;
        var text = escapeHTML(state.text);
        if ( $(originalOption).data('primary') == 1 ) {
            state.is_primary = true;
            return '<span class="category_label is_primary" data-id="'+escapeHTML(state.id)+'">' + text + "</span>";
        } else {
            state.is_primary = false;
            return '<span class="category_label" data-id="'+escapeHTML(state.id)+'">' + text + "</span>";
        }
    }
    $("select", $('#entry-listing-table .category')).select2({
        formatResult: format,
        formatSelection: format,
        escapeMarkup: function(m) { return m; }
    })
    
    $('#entry-listing-table .category').each(function(){
        var container = $(this);
        function find(id){
            var data = $('select', container).select2('data');
            for(var i=0; i<data.length; i++){
                if(data[i].id == id) return data[i];
            }
            return;
        }
        function setPrimary(id){
            if(id == 'first') {
                id = $('.category_label:first', container).data('id');
            }
            if(!id) return;
            var data = $('select', container).select2('data');
            for(var i=0; i<data.length; i++){
                var data_id = data[i].id;
                if(data_id == id) {
                    data[i].is_primary = true;
                    $('.category_label[data-id='+data_id+']', container).addClass('is_primary');
                } else {
                    data[i].is_primary = false;
                    $('.category_label[data-id='+data_id+']', container).removeClass('is_primary');
                }
            }
        }
        $('select', container).on('select2-selecting', function(e){
            var state = e.object;
            var originalOption = state.element;
            if(container.find('.is_primary').size() == 0){
                $(originalOption).data('primary', 1);
            } else {
                $(originalOption).data('primary', 0);
            }
        });
        $('select', container).on('change', function(e){
            var removed = e.removed;
            if(removed) {
                if(container.find('.is_primary').size() == 0 || removed.is_primary){
                    setPrimary('first');
                }
            }
        });
        $(container).on('click', ".category_label", function(e){
            var obj = $(e.target);
            setPrimary(obj.data('id'));
        });
    });
    
    $('form#entry-listing-form').submit(function(){
        $.each($('#entry-listing-table .category'), function(){
            var container = $(this);
            var data = $("select", container).select2('data');
            var category_id;
            var category_ids = [];
            $.each(data, function(){
                var state = this;
                if(state.is_primary) {
                    category_id = state.id;
                } else {
                    category_ids.push(state.id);
                }
            });
            container.find('.category_id:hidden').val(category_id);
            container.find('.category_ids:hidden').val(category_ids.join(','));
        });
        return true;
    });
})(jQuery);});
