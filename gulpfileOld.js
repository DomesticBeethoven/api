var gulp = require('gulp');
var zip = require('gulp-zip');
var replace = require('gulp-replace');
var newer = require('gulp-newer');
var dateformat = require('dateformat');
var del = require('del');
var packageJson = require('./package.json');
var bump = require('gulp-bump');
var fs = require('fs');
var exist = require('@existdb/gulp-exist');
var existConfig = require('./existConfig.json');
var existClient = exist.createClient(existConfig);
var git = require('git-rev-sync');
var runSequence = require('run-sequence').use(gulp)

//handles xqueries
gulp.task('xql', function(){

    return gulp.src('exist/xql/**/*')
        .pipe(newer('build/resources/xql/'))
        .pipe(gulp.dest('build/resources/xql/'));
});

//deploys xql to exist-db
gulp.task('deploy-xql', gulp.series('xql', function() {

    return gulp.src(['**/*'], {cwd: 'build/resources/xql/'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/resources/xql/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/resources/xql/'}));
}))

//watches xql for changes
gulp.task('watch-xql',function() {
    return gulp.watch(['exist/xql/**/*','exist/xqm/**/*'], gulp.series('deploy-xql'));
})



//handles controller changes
gulp.task('controller', function(){

    return gulp.src('exist/eXist-db/controller.xql')
        .pipe(newer('build/'))
        .pipe(gulp.dest('build/'));
});

//deploys xql to exist-db
gulp.task('deploy-controller', gulp.series('controller', function() {

    return gulp.src(['controller.xql'], {cwd: 'build/'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/'}));
}))

//watches controller changes
gulp.task('watch-controller',function() {
    return gulp.watch('exist/eXist-db/controller.xql', gulp.series('deploy-controller'));
})

//handles xslt
gulp.task('xslt', function(){
    return gulp.src('./exist/xslt/**/*')
        .pipe(newer('./build/resources/xslt/'))
        .pipe(gulp.dest('./build/resources/xslt/'));
});

//deploys xslt to exist-db
gulp.task('deploy-xslt', gulp.series('xslt', function() {
    return gulp.src('**/*', {cwd: './build/resources/xslt/'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/resources/xslt/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/resources/xslt/'}));
}))

//watches xslt for changes
gulp.task('watch-xslt',function() {
    return gulp.watch('exist/xslt/**/*', gulp.series('deploy-xslt'));
})

//handles html
gulp.task('html', function(){
    return gulp.src('./exist/html/**/*')
        .pipe(newer('./build/'))
        .pipe(gulp.dest('./build/'));
});

//deploys html to exist-db
gulp.task('deploy-html', gulp.series('html', function() {
    return gulp.src('**/*.html', {cwd: './build/'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/'}));
}))

//watches html for changes
gulp.task('watch-html',function() {
    return gulp.watch('exist/html/**/*', gulp.series('deploy-html'));
})

//handles data
gulp.task('data', function(){
    return gulp.src('./data/**/*')
        .pipe(newer('./build/content/'))
        .pipe(gulp.dest('./build/content/'));
});

//deploys data to exist-db
gulp.task('deploy-data', gulp.series('data', function() {
    return gulp.src('**/*', {cwd: 'build/content/'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/content/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/content/'}));
}))

//watches xslt for changes
gulp.task('watch-data',function() {
    return gulp.watch('data/**/*', gulp.series('deploy-data'));
})

//bump version on patch level
/*gulp.task('bump-patch', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'patch'}))
        .pipe(gulp.dest('./'));
});*/

//bump version on minor level
/*gulp.task('bump-minor', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'minor'}))
        .pipe(gulp.dest('./'));
});*/

//bump version on major level
/*gulp.task('bump-major', function () {
    return gulp.src(['./package.json'])
        .pipe(bump({type: 'major'}))
        .pipe(gulp.dest('./'));
});*/

//set up basic xar structure
gulp.task('xar-structure', function() {
    return gulp.src(['./exist/eXist-db/**/*'])
        .pipe(replace('$$deployed$$', dateformat(Date.now(), 'isoUtcDateTime')))
        .pipe(replace('$$version$$', getPackageJsonVersion()))
        .pipe(replace('$$desc$$', packageJson.description))
        .pipe(replace('$$license$$', packageJson.license))
        .pipe(gulp.dest('./build/'));

});

//empty build folder
gulp.task('del', function() {
    return del(['./build/**/*','./dist/' + packageJson.name + '-' + getPackageJsonVersion() + '.xar']);
});

//reading from fs as this prevents caching problems
function getPackageJsonVersion() {
    return JSON.parse(fs.readFileSync('./package.json', 'utf8')).version;
}

gulp.task('git-info',function(done) {
    console.log('Git Information:')
    console.log('  short:    ' + git.short())
    console.log('  url:      ' + git.remoteUrl())
    console.log('  is dirty: ' + git.isDirty())
    console.log('  long:     ' + git.long())
    console.log('  branch:   ' + git.branch())
    console.log('  tag:      ' + git.tag())
    console.log('  date:     ' + git.date())
    done()
});

function getGitInfo() {
    return {short: git.short(),
            url: 'https://github.com/BeethovensWerkstatt/module2/commit/' + git.short(),
            dirty: git.isDirty()}
}


/**
 * deploys the current build folder into a (local) exist database
 */
gulp.task('deploy', function() {
    return gulp.src('**/*', {cwd: 'build'})
        .pipe(existClient.newer({target: "/db/apps/bith-api/"}))
        .pipe(existClient.dest({target: '/db/apps/bith-api/'}));
})

gulp.task('watch', gulp.parallel('watch-xql','watch-xslt','watch-data','watch-controller','watch-html'));


gulp.task('dist-finish', function() {
    return gulp.src('./build/**/*')
        .pipe(zip(packageJson.name + '-' + getPackageJsonVersion() + '.xar'))
        .pipe(gulp.dest('./dist'));
})

//creates a dist version
gulp.task('dist', gulp.series('xar-structure', gulp.parallel('xql','xslt','data','html'), 'dist-finish'))

//creates a dist version with a version bump at patch level
/*gulp.task('dist-patch', gulp.series('bump-patch', 'dist'));*/

//creates a dist version with a version bump at minor level
/*gulp.task('dist-patch', gulp.series('bump-minor', 'dist'));*/

//creates a dist version with a version bump at major level
/*gulp.task('dist-patch', gulp.series('bump-major', 'dist']));*/


gulp.task('default', function() {
    console.log('')
    console.log('INFO: There is no default task, please run one of the following tasks:');
    console.log('');
    console.log('  "gulp dist"       : creates a xar from the current sources');
    console.log('  "gulp bump-patch" : bumps the semver version of this package at patch level');
    console.log('  "gulp bump-minor" : bumps the semver version of this package at minor level');
    console.log('  "gulp bump-major" : bumps the semver version of this package at major level');
    console.log('');
});
